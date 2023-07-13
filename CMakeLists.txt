cmake_minimum_required(VERSION 3.8)

PROJECT(test)

find_package(Wt REQUIRED COMPONENTS wt http )

ADD_EXECUTABLE(wt_test_chart.wt wt_test_chart.C)

TARGET_LINK_LIBRARIES(wt_test_chart.wt Wt::HTTP hpdf)

INSTALL(TARGETS wt_test_chart.wt DESTINATION bin)
