{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        generate:
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "x86_64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ]
          (
            system:
            generate (
              let
                pkgs = import nixpkgs { inherit system; };
              in
              {
                inherit pkgs;
                beamPackages = pkgs.beam29Packages.extend (_: prev: { elixir = prev.elixir_1_20; });
              }
            )
          );

    in
    {
      devShells = forAllSystems (
        { pkgs, beamPackages, ... }:
        {
          default = pkgs.mkShell {
            packages = [
              beamPackages.elixir
              beamPackages.elixir-ls
            ];
          };
        }
      );

      templates.default = {
        path = ./flake-template;
      };
    };
}
