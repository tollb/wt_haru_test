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

To see all of the available test cases:
```
$ nix flake show github:tollb/wt_haru_test
```

To build all of the test cases (optional):
```
$ nix run github:tollb/wt_haru_test#all
```

To run a test with libharu 2.3.0 (that appears to work):
```
$ nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_2_3_0 -- --http-listen=localhost:8080
```
Then, browse to: http://localhost:8080 and Click the "Export to PDF" button.

To run a test that fails with a libharu 2.4.3 build:
```
$ nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_2_4_3 -- --http-listen=localhost:8080
```
Then, browse to: http://localhost:8080 and Click the "Export to PDF" button.
Note: missing y-axis labels and title, compared with libharu 2.3.0.

Reverting commit fb11e6913 from the 2.4.3 branch seems to help, as can be seen with:
```
$ nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_2_4_3_revert_fb11e6913 -- --http-listen=localhost:8080
```

The unreleased libharu development branch, as of 20230509, no longer seems to have this issue:
```
$ nix run github:tollb/wt_haru_test#test_chart_wt4_10_0_libharu_devel_20230509 -- --http-listen=localhost:8080
```
