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
