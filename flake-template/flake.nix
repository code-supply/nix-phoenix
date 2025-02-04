{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        generate:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "x86_64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ] (system: generate { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default =
            with pkgs;
            mkShell {
              packages = [
                elixir
                elixir-ls
              ];
            };
        }
      );

      packages = forAllSystems (
        { pkgs, ... }:
        let
          mixNixDeps = pkgs.callPackages ./deps.nix { };
        in
        {
          default =
            with pkgs;
            beamPackages.mixRelease {
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

                ln -sfv ${tailwindcss}/bin/tailwindcss "$tailwind_path"
                ln -sfv ${esbuild}/bin/esbuild "$esbuild_path"
                ln -sfv ${mixNixDeps.heroicons} deps/heroicons

                mix do \
                  app.config --no-deps-check --no-compile, \
                  assets.deploy --no-deps-check
              '';
            };
        }
      );
    };
}
