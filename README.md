# Corrupt PDF output with Haru 2.4.3

WCartesianChart w/YAxis Title outputs corrupt PDF with libharu 2.4.3

There appears to be a bug in libharu versions 2.4.0, 2.4.1, 2.4.2, and 2.4.3 where some
floating point values are written incorrectly by the HPDF_FToA() function. This can
result in corrupt PDF files where only a portion of the intended content is visible.

This directory contains an example program, **wt_test_chart.C**, that demonstrates the issue,
along with a CMakeLists.txt for building.

See issue: https://github.com/libharu/libharu/pull/187

It appears it may be fixed on development branch:
https://github.com/libharu/libharu/issues/258

For reproducibility, there are also two nix related files: nix.flake and nix.lock, that
make it easy to build test cases using the test program linked with wt 4.10.0 and various
versions of libharu:
