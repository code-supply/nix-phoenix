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
                beamPackages = pkgs.beam29Packages.extend (
                  _: prev: {
                    elixir = prev.elixir_1_20;
                    elixir-ls = prev.elixir-ls.override { elixir = prev.elixir_1_20; };
                  }
                );
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

      packages = forAllSystems (
        { pkgs, beamPackages, ... }:
        let
          mixNixDeps = pkgs.callPackages ./deps.nix { inherit beamPackages; };
        in
        {
          default = beamPackages.mixRelease {
            inherit mixNixDeps;
            pname = "my_phoenix_app";
            src = ./.;
            version = "0.0.0";

            DATABASE_URL = "";
            SECRET_KEY_BASE = "";

            postBuild = ''
              tailwind_path="$(mix do \
                app.config --no-deps-check --no-compile, \
                eval 'Tailwind.bin_path() |> IO.puts()')"
              esbuild_path="$(mix do \
                app.config --no-deps-check --no-compile, \
                eval 'Esbuild.bin_path() |> IO.puts()')"

              ln -sfv ${pkgs.tailwindcss}/bin/tailwindcss "$tailwind_path"
              ln -sfv ${pkgs.esbuild}/bin/esbuild "$esbuild_path"
              ln -sfv ${pkgs.mixNixDeps.heroicons} deps/heroicons

              mix do \
                app.config --no-deps-check --no-compile, \
                assets.deploy --no-deps-check
            '';
          };
        }
      );
    };
}
