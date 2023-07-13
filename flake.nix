# See README.md for additional information on how to use this nix flake...

# Note: This flake.nix was originally created with "nix flake init -t templates#c-hello", also available at:
# https://raw.githubusercontent.com/NixOS/templates/0edaa0637331e9d8acca5c8ec67936a2c8b8749b/c-hello/flake.nix
# Only the x86_64-linux system was actually tested...

{
  description = "Demonstrate a libharu bug using wt chart";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {
      # A Nixpkgs overlay.
      overlay = final: prev:
        let
          # build wt and test app with specified boost (1.82)
          boost_for_test = prev.boost182;

          haruBuilds = {
            libharu_2_4_3 = assert prev.libharu.version == "2.4.3";
              prev.libharu;

            libharu_2_3_0 = prev.libharu.overrideAttrs (finalAttrs: previousAttrs: {
              version = "2.3.0";
              src = prev.pkgs.fetchFromGitHub {
                owner = "libharu";
                repo = "libharu";
                rev = "RELEASE_2_3_0";
                sha256 = "15s9hswnl3qqi7yh29jyrg0hma2n99haxznvcywmsp8kjqlyg75q";
              };
            });

            libharu_2_4_3_revert_fb11e6913 = assert prev.libharu.version == "2.4.3";
              prev.libharu.overrideAttrs (finalAttrs: previousAttrs: {
                version = "2.4.3_revert_fb11e6913";
                patches = [
                  (prev.fetchpatch {
                    url = "https://github.com/libharu/libharu/commit/fb11e6913f9da9ae350befa6deb560c10ac0afcd.patch";
                    sha256 = "sha256-etY1GmZUV5w13AFlLcIaRYVE5t8BJBkBYMzvmzOgdwo=";
                    revert = true;
                  })
                ];
              });

            libharu_devel_20230509 = prev.libharu.overrideAttrs (finalAttrs: previousAttrs: {
              version = "devel_20230509";
              src = prev.pkgs.fetchFromGitHub {
                owner = "libharu";
                repo = "libharu";
                rev = "91f31402ba60ad8181bf398a04d89ac99cedf032";
                sha256 = "sha256-9OOdwHOwcJO3acxAU6yPo2BJuugaS7M4OJzb37ZjRTM=";
              };
            });
          };

          wt4_10_0 = prev.wt4.overrideAttrs (finalAttrs: previousAttrs:
            let version = "4.10.0"; in {
              inherit version;
              src = prev.fetchFromGitHub {
                owner = "emweb";
                repo = "wt";
                rev = version;
                sha256 = "sha256-05WZnyUIwXwJA24mQi5ATCqRZ6PE/tiw2/MO1qYHRsY=";
              };
            });

          # build wt libraries with each of the libharu versions in haruBuilds, along with version of boost in boost_for_test
          wtBuilds = prev.lib.mapAttrs'
            (name: value:
              prev.lib.nameValuePair ("wt4_10_0_" + name) ({ wt = wt4_10_0.override { boost = boost_for_test; libharu = value; }; haru = value; })
            )
            haruBuilds;

          exampleBuilds = (prev.lib.mapAttrs'
            (name: value: prev.lib.nameValuePair
              ("test_chart_" + name)
              (
                with final; stdenv.mkDerivation {
                  pname = "test_chart_${name}";
                  inherit version;

                  src = ./.;

                  nativeBuildInputs = [ cmake makeWrapper ];
                  buildInputs = [ value.wt value.haru boost_for_test ];

                  postFixup = ''
                    wrapProgram $out/bin/wt_test_chart.wt \
                      --add-flags "--docroot=${value.wt.out}/share/Wt"
                  '';
                }
              ))
            wtBuilds);

          combinedBuild = prev.runCommand "all"
            {
              nativeBuildInputs = prev.lib.mapAttrsToList (name: value: value) exampleBuilds;
            }
            ''
              mkdir -p $out/bin
              cat << EOF > "$out/bin/all"
              #!/bin/sh
              echo "To run an individual test, specify the full flake. See: nix flake show"
              EOF
              chmod +x "$out/bin/all"
            '';

          exampleBuildMap = {
            inherit combinedBuild;
            inherit exampleBuilds;
            allExampleBuilds = exampleBuilds // { all = combinedBuild; };
          };

        in
        exampleBuilds // exampleBuildMap;

      packages = forAllSystems (system:
        nixpkgsFor.${system}.allExampleBuilds
      );

      defaultPackage = forAllSystems (system:
        nixpkgsFor.${system}.combinedBuild
      );

      # provide apps for nix run...
      apps = forAllSystems (system:
        (nixpkgs.lib.mapAttrs (name: value: { type = "app"; program = "${value}/bin/wt_test_chart.wt"; })
          nixpkgsFor.${system}.exampleBuilds)
      );
    };
}
