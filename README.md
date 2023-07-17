# Wt PDF output with various versions of libharu

There appears to be a bug in libharu versions 2.4.0 through 2.4.3 where some
floating point values are written incorrectly by the HPDF_FToA() function. This can
result in corrupt PDF files where only a portion of the intended content is visible.

This directory contains an example program, **wt_test_chart.C**, that demonstrates the issue,
along with a CMakeLists.txt for building.

See issue: https://github.com/libharu/libharu/pull/187

It appears it may be fixed on development branch:
https://github.com/libharu/libharu/issues/258

For reproducibility, there are also two nix related files: nix.flake and nix.lock, that
make it easy to build test cases using the test program linked with wt 4.10.0 and various
versions of libharu.

## Test procedure

To test with libharu 2.3.0 (appears to work):
```
nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_2_3_0 -- --http-listen=localhost:8080
```
Then, browse to: http://localhost:8080 and Click the "Export to PDF" button.

To test with a libharu 2.4.3 build (fails):
```
nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_2_4_3 -- --http-listen=localhost:8080
```
Then, browse to: http://localhost:8080 and Click the "Export to PDF" button.
Note: missing y-axis labels, title, and legend when compared with libharu 2.3.0 output.

## Other build/test options that seem to work:

Reverting commit fb11e6913 from the 2.4.3 branch:
```
nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_2_4_3_revert_fb11e6913 -- --http-listen=localhost:8080
```

Also, the issue seems to be addressed on the libharu development branch, as of 20230509:
```
nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_devel_20230509 -- --http-listen=localhost:8080
```

## Other notes:

The nix flake has only been tested with x86_64-linux.

To see all available builds:
```
nix flake show github:tollb/wt_haru_test
```
