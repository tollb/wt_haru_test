#include <Wt/Chart/WCartesianChart.h>
#include <Wt/Http/Request.h>
#include <Wt/Http/Response.h>
#include <Wt/WApplication.h>
#include <Wt/WEnvironment.h>
#include <Wt/WPainter.h>
#include <Wt/WPdfImage.h>
#include <Wt/WPushButton.h>
#include <Wt/WResource.h>
#include <Wt/WStandardItemModel.h>
#include <Wt/WLink.h>

using namespace Wt;

void HPDF_STDCALL error_handler(HPDF_STATUS error_no, HPDF_STATUS detail_no, void *user_data) {
  /*
   * Ignore 0x102b...Wt::WPdfImage.c tries to set a true-type font first and fails when we are
   * using the Base-14 builtin fonts. It succeeds on retry, so the message is harmless and is ignored.
   */
  if (error_no == 0x102b)
    return;
  std::stringstream hexcode_ss;
  hexcode_ss << std::hex << static_cast<HPDF_UINT>(error_no);
  log("error") << "libharu error: error_no=" << hexcode_ss.str()
               << ", detail_no=" << static_cast<HPDF_UINT>(detail_no);
}

class TestApp : public WApplication {
public:
  TestApp(const WEnvironment& env);

  Chart::WCartesianChart* chart_ = nullptr;
};

class ChartPdfResource : public Wt::WResource
{
public:
  ChartPdfResource() { };
  ~ChartPdfResource()
    {
      beingDeleted();
    }

  void handleRequest(const Wt::Http::Request& request, Wt::Http::Response& response)
  {
    auto app = dynamic_cast<TestApp *>(wApp);
    WApplication::UpdateLock lock(app);
    if (!lock)
      return;

    suggestFileName("test.pdf");
    response.setMimeType("application/pdf");

    HPDF_Doc pdf = HPDF_New(error_handler, 0);
    if (!pdf) {
      response.setStatus(500);
      response.setMimeType("text/html");
      log("error") << "ChartPdfResource::handleRequest returning 500: HPDF_New failed";
      response.out() << "500" << std::endl;
      return;
    }

    HPDF_SetCompressionMode(pdf, HPDF_COMP_ALL);

    try {
      auto page = HPDF_AddPage(pdf);

      WLength width(11.0*72);
      WLength height(8.5*72);

      HPDF_Page_SetWidth(page, width.toPixels());
      HPDF_Page_SetHeight(page, height.toPixels());
      HPDF_Page_GSave(page);

      Wt::WPdfImage image(pdf, page, 0, 0, width.toPixels(), height.toPixels());
      {
        Wt::WPainter p(&image);
        p.setWindow(0, 0, 1.45*11.0*72, 1.45*8.5*72);
        p.setViewPort(0.5*72, 0.5*72, 10.0*72, 7.5*72);
        app->chart_->paint(p);
      }
      image.write(response.out());
      HPDF_Free(pdf);
    }
    catch (std::runtime_error &e) {
      int status = 500;
      response.setStatus(status);
      response.setMimeType("text/html");
      log("error") << "ChartPdfResource::handleRequest returning " << status << ": " << e.what();
      response.out() << std::to_string(status) << std::endl;
      HPDF_Free(pdf);
      return;
    }
  }
};

TestApp::TestApp(const WEnvironment& env) : WApplication(env)
{
  setTitle("WCartesianChart with Vertical Y-Axis Title");

  auto model = std::make_shared<WStandardItemModel>(20, 2);
  model->setHeaderData(1, Orientation::Horizontal, "Data Point");
  for (int r = 0; r < model->rowCount(); ++r)
    for (int c = 0; c < model->columnCount(); ++c)
      model->setData(model->index(r, c), r * ((c == 1) ? 1 : -1));

  chart_ = root()->addNew<Chart::WCartesianChart>();
  chart_->resize(500, 500);
  chart_->setModel(model);
  chart_->addSeries(std::make_unique<Chart::WDataSeries>(1));

  chart_->setAutoLayoutEnabled();
  chart_->axis(Chart::Axis::X).setTitle("X-Axis Title");
  chart_->axis(Chart::Axis::X).setTitleOrientation(Orientation::Horizontal);
  chart_->axis(Chart::Axis::Y).setTitle("Y-Axis Title");
  chart_->axis(Chart::Axis::Y).setTitleOrientation(Orientation::Vertical);
  chart_->setLegendEnabled(true);

  auto chart_pdf_resource = std::make_shared<ChartPdfResource>();

  auto export_pdf_button = root()->addNew<WPushButton>("Export to PDF");
  export_pdf_button->setLink(WLink(chart_pdf_resource));
}

int main(int argc, char **argv)
{
  return WRun(argc, argv, [](const WEnvironment& env) {return std::make_unique<TestApp>(env);});
}
