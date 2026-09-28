my_head <- head

my_write.csv <- function(x, path) {
  write.csv(x, file = path, row.names = F)
}
