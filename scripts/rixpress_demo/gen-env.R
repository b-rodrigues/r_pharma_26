library(rix)

rix(
  date = "2026-04-30",
  r_pkgs = c(
    "dplyr",
    "ggdag",
    "igraph",
    "quarto",
    "reticulate",
    "rix",
    "visNetwork"
  ),
  git_pkgs = list(
    list(
      package_name = "rixpress",
      repo_url = "https://github.com/ropensci/rixpress",
      commit = "4993b387c777152f51d9587c3e90e905bb64e1ce"
    )
  ),
  py_conf = list(
    py_version = "3.14",
    py_pkgs = c(
      "polars"
    )
  ),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)
