# Start a new Phoenix project with Nix

## Prerequisites

- Nix
- Local Postgres
- (optional) [direnv](https://direnv.net/)

### direnv

Examples assume you've set this up. Use `nix develop .` instead of `direnv allow` if you don't want direnv.

To install with Home Manager and nix-direnv caching:

```nix
home.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

## Instructions

### Initialise

```shell
mkdir my_new_project # underscores mean you can skip an argument to mix phx.new
cd my_new_project
git init
nix flake init -t github:code-supply/nix-phoenix
direnv allow
mix phx.new . # and say Y to everything
echo .direnv >> .gitignore # we don't want to store the direnv cache in git
```

### Add deps_nix

Follow the [deps_nix installation instructions](https://github.com/code-supply/deps_nix?tab=readme-ov-file#installation).

Fetch the deps_nix dependency:

```shell
mix deps.get
```

### Generate the initial deps.nix file

```shell
mix deps.nix
```

### Build the project

```shell
git add . # make files available to the Nix flake
nix build --print-build-logs # short option is -L
```

### Create a local database

```shell
DATABASE_URL=ecto://postgres:postgres@localhost/my_new_project \
MIX_ENV=prod \
SECRET_KEY_BASE="$(mix phx.gen.secret)" \
mix ecto.create
```

### Run the built artifact

```shell
DATABASE_URL=ecto://postgres:postgres@localhost/my_new_project \
PHX_SERVER=true \
RELEASE_COOKIE=asdf \
SECRET_KEY_BASE="$(mix phx.gen.secret)" \
./result/bin/my_new_project start
```
