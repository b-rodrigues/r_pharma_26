library(igraph)
library(rixpress)

list(
  rxp_py_file(
    name = mtcars_pl,
    path = 'data/mtcars.csv',
    read_function = "lambda x: polars.read_csv(x, separator='|')"
  ),

  rxp_py(
    name = mtcars_pl_am,
    expr = "mtcars_pl.filter(polars.col('am') == 0)",
    user_functions = "functions.py",
    encoder = "write_to_csv"
  ),

  rxp_r(
    name = mtcars_head,
    expr = my_head(mtcars_pl_am),
    user_functions = "functions.R",
    encoder = "my_write.csv",
    decoder = "read.csv"
  ),

  rxp_py(
    name = mtcars_tail_py,
    expr = "mtcars_head.tail()",
    user_functions = "functions.py",
    encoder = "write_to_csv",
    decoder = "read_from_csv"
  ),

  rxp_r(
    name = mtcars_mpg,
    expr = dplyr::select(mtcars_tail_py, mpg),
    decoder = "read.csv"
  ),

  rxp_qmd(
    name = page,
    qmd_file = "my_doc/page.qmd",
    additional_files = c("my_doc/content.qmd", "my_doc/images")
  )
) |>
  rxp_populate(project_path = ".", build = TRUE)

