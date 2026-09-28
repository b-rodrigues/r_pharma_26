library(rix)

rix(date = "2026-01-14",
    r_pkgs = c("tidyr", "dplyr", "ggplot2", "languageserver"),
    py_conf = list(
      py_version = "3.13", 
      py_pkgs = c("polars", "scikit-learn")
    ),
    system_pkgs = NULL,
    git_pkgs = NULL,
    tex_pkgs = NULL,
    ide = "none",
    project_path = ".",
    overwrite = TRUE)
