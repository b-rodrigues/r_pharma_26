library(yardstick)
library(dplyr)

get_cm <- function(combined_df){
  cm_obj = combined_df %>%
  mutate(target = as.factor(target), 
        prediction = as.factor(prediction)) %>%
  conf_mat(truth = target, estimate = prediction)

as.data.frame(cm_obj$table)
}
