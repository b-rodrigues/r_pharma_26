let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2026-09-23.tar.gz") {};

  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
    quarto
    rix
    rUM
    tarchetypes
    targets
    withr
      ;
  };

 system_packages = builtins.attrValues {
  inherit (pkgs) R glibcLocalesUtf8 quarto nix;
};

  in
  pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [ system_packages rpkgs ];

    shellHook = '' Rscript -e "targets::tar_make()" '';
  }

