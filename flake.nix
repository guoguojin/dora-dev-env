{
  description = "Go development shell";

  inputs = {
    nixpkgs.url =
      "github:nixos/nixpkgs/nixpkgs-unstable"; # use the unstable packages for more up-to-date packages
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        goVersion = 26;

        pkgs = import nixpkgs { inherit system; };
      in {
        overlays.default = final: prev: {
          go = final."go_1_${toString goVersion}";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            delve
            ripgrep
            go
            gopls
            golangci-lint
            gnumake
            pre-commit
            diffutils
            gofumpt
            gotools
            gotests
            gomodifytags
            impl
            buf
            jq
            python314
            awscli2
          ];

          # CGO runtime header file has a warning about compiling with optimizations which will
          # prevent CGO from running inside a flake based nix shell.
          # To work around this, we need to disable the hardening requirement for the shell
          # or set the environment variable CGO_ENABLED=0 and disable CGO.
          # As we don't know yet if we will need CGO, we have chosen to just disable the hardening for the shell
          hardeningDisable = [ "fortify" ]; # so that delve will work

          shellHook = ''
            if [ -z $XDG_CACHE ]; then
              echo "Setting XDG_CACHE to $HOME/.cache"
              export XDG_CACHE=$HOME/.cache
            fi

            export SHELL_PATH=$XDG_CACHE/dev-shell/''${PWD##*/}

            if [ ! -d $SHELL_PATH ]; then
              mkdir -p $SHELL_PATH
            fi

            export GOROOT=$(nix path-info nixpkgs#go_1_${toString goVersion})/share/go
            export GOPATH=$SHELL_PATH/go
            if [ ! -d $GOPATH ]; then
              mkdir -p $GOPATH
            fi
            export GOBIN=$GOPATH/bin

            export PATH=$GOPATH/bin:$PATH
            export GOPRIVATE="github.com/dora-network"
            export SPANNER_EMULATOR_HOST=localhost:9010

            if [ -f go.mod ]; then
              echo "Found go.mod, running tidy"
              go mod tidy
            fi

            echo "Go development shell"
            echo "$(go version)"
            echo "GOROOT=$GOROOT"
            echo "GOPATH=$GOPATH"
            echo "GOBIN=$GOBIN"
          '';
        };
      }
    );
}
