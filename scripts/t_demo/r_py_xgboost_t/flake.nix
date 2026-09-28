{
  description = "testcraft_expectations_t — a T data analysis project";

  inputs = {
    nixpkgs.url = "github:rstats-on-nix/nixpkgs/2026-06-23";
    flake-utils.url = "github:numtide/flake-utils";
    t-lang.url = "github:b-rodrigues/tlang/v0.55.3";
  };

  nixConfig = {
    extra-substituters = [
      "https://rstats-on-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
    ];
  };

  outputs = { self, nixpkgs, flake-utils, t-lang }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # R environment
        r-env = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            t-lang.packages.${system}.tlang-r
            arrow
          ];
        };

        # Python environment
        py-env = pkgs.python314.withPackages (python-pkgs: with python-pkgs; [
          deepdiff
          pandas
        ]);

        # Julia environment
        juliaPkg = pkgs.julia-lts.withPackages [ "JSON" ];

        # Additional Tools
        additionalTools = with pkgs; [
          which
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            t-lang.packages.${system}.default
            r-env
            py-env
            juliaPkg
            t-lang.packages.${system}.tlang-julia-path
          ] ++ additionalTools;

          shellHook = ''
            export PYTHONPATH="${t-lang.packages.${system}.default}/share/tlang/py-package/src:''${PYTHONPATH:-}"
            export JULIA_LOAD_PATH=":${t-lang.packages.${system}.tlang-julia-path}:''${JULIA_LOAD_PATH:-}"
            # Create a local Julia depot directory for sandbox guards
            julia_depot_dir="$PWD/.t_julia_depot"
            mkdir -p "$julia_depot_dir/config"
            cat > "$julia_depot_dir/config/startup.jl" <<'EOF'
const _tlang_pkg_id = Base.PkgId(Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"), "Pkg")
const _tlang_real_pkg = Base.require(_tlang_pkg_id)

module _TlangGuardPkg
  import Main: _tlang_real_pkg
  export add, rm, update, develop
  msg = "Don't use imperative package management in this T Julia environment. Declare packages in tproject.toml, run `t update`, and re-enter `nix develop`."
  add(args...; kwargs...) = error(msg)
  rm(args...; kwargs...) = error(msg)
  update(args...; kwargs...) = error(msg)
  develop(args...; kwargs...) = error(msg)
  # Delegate read-only Pkg operations to the real Pkg module
  const _real = _tlang_real_pkg
  status(args...; kwargs...) = _real.status(args...; kwargs...)
  dependencies(args...; kwargs...) = _real.dependencies(args...; kwargs...)
  instantiate(args...; kwargs...) = _real.instantiate(args...; kwargs...)
  activate(args...; kwargs...) = _real.activate(args...; kwargs...)
  project(args...; kwargs...) = _real.project(args...; kwargs...)
  compat(args...; kwargs...) = _real.compat(args...; kwargs...)
end

if isinteractive()
  const _tlang_repl_id = Base.PkgId(Base.UUID("3fa0cd96-eef1-5676-8a61-b3b8758bbffb"), "REPL")
  try
    _tlang_repl = Base.require(_tlang_repl_id)

    function _tlang_install_packages_hook(pkgs::Vector{Symbol})
      pkg_str = join(string.(pkgs), ", ")
      println(" │ Packages [", pkg_str, "] not found, but packages named [", pkg_str, "] are available from")
      println(" │ a registry.")
      println(" │ Install packages?")
      println(" │   (project) pkg> add ", pkg_str)
      print(" └ (y/n) [y]: ")
      flush(stdout)
      response = lowercase(strip(readline(stdin)))
      if response == "" || response == "y" || response == "yes"
        println("\nDon't use interactive package installation in this T Julia environment.")
        println("Declare packages in tproject.toml, run `t update`, and re-enter `nix develop`.\n")
      else
        println("Cancelled.")
      end
      return false
    end

    pushfirst!(_tlang_repl.install_packages_hooks, _tlang_install_packages_hook)

    # Replace Pkg in loaded_modules with the guard
    Base.loaded_modules[_tlang_pkg_id] = _TlangGuardPkg
  catch err
    # Suppress any startup errors so Julia doesn't fail to launch
  end

  using Pkg
end # if isinteractive()
EOF
            export JULIA_DEPOT_PATH="$julia_depot_dir:''${JULIA_DEPOT_PATH:-}"
            # Create a local R profile directory for sandbox guards
            r_profile_dir="$PWD/.t_r_profile"
            mkdir -p "$r_profile_dir"
            cat > "$r_profile_dir/.Rprofile" <<'EOF'
options(prompt='r> ', continue='r+ ')
install.packages <- function(...) stop("Don't use install.packages() in this T R environment. Declare packages in tproject.toml, run `t update`, and re-enter `nix develop`.", call. = FALSE)
update.packages <- function(...) stop("Don't use update.packages() in this T R environment. Declare packages in tproject.toml, run `t update`, and re-enter `nix develop`.", call. = FALSE)
remove.packages <- function(...) stop("Don't use remove.packages() in this T R environment. Declare packages in tproject.toml, run `t update`, and re-enter `nix develop`.", call. = FALSE)
EOF
            export R_PROFILE_USER="$r_profile_dir/.Rprofile"
            # Create a local Python guard directory
            python_guard_dir="$PWD/.t_python_guard"
            python_guard_bin="$python_guard_dir/bin"
            python_guard_lib="$python_guard_dir/python"
            mkdir -p "$python_guard_bin" "$python_guard_lib"

            for tool in pip pip3 uv poetry conda mamba micromamba easy_install; do
              cat > "$python_guard_bin/$tool" <<EOF
#!/usr/bin/env sh
printf "Don't use $tool in this T Python environment. Declare packages in tproject.toml, run 't update', and re-enter 'nix develop'.\n" >&2
exit 1
EOF
              chmod +x "$python_guard_bin/$tool"
            done

            cat > "$python_guard_lib/pip.py" <<'EOF'
raise SystemExit("Don't use python -m pip in this T Python environment. Declare packages in tproject.toml, run `t update`, and re-enter `nix develop`.")
EOF

            export PATH="$python_guard_bin:$PATH"
            export PYTHONPATH="$python_guard_lib:''${PYTHONPATH:-}"
            echo "=================================================="
            echo "T Project: testcraft_expectations_t"
            echo "=================================================="
            echo ""
            echo "Available commands:"
            echo "  t repl              - Start T REPL"
            echo "  t run <file>        - Run a T file"
            echo "  t test              - Run tests"
            echo ""
            echo "To add dependencies:"
            echo "  * Add them to tproject.toml"
            echo "  * Run 't update' to sync flake.nix"
            echo ""
          '';
        };
      }
    );
}
