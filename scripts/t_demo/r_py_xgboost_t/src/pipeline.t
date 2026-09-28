-- r_py_xgboost_t pipeline mimicking rixpress_demos/r_py_xgboost

p = pipeline {
  -- Load data
  dataset_np = pyn(
    command = <{
from numpy import loadtxt
dataset_np = loadtxt("data/pima-indians-diabetes.csv", delimiter=",")
    }>,
    include = ["data/pima-indians-diabetes.csv"]
  )

  -- Extract features and target
  X = pyn(command = <{ X = dataset_np[:,0:8] }>)
  Y = pyn(command = <{ Y = dataset_np[:,8] }>)

  -- Split data
  splits = pyn(
    command = <{
from sklearn.model_selection import train_test_split
splits = train_test_split(X, Y, test_size=0.33, random_state=7)
    }>
  )

  -- Extract splits
  X_train = pyn(command = <{ X_train = splits[0] }>)
  X_test  = pyn(command = <{ X_test = splits[1] }>)
  y_train = pyn(command = <{ y_train = splits[2] }>)
  y_test  = pyn(command = <{ y_test = splits[3] }>)

  -- Train model
  trained_model = pyn(
    command = <{
from xgboost import XGBClassifier
trained_model = XGBClassifier(use_label_encoder=False, eval_metric="logloss").fit(X_train, y_train)
    }>
  )

  -- Make predictions
  y_pred = pyn(command = <{ y_pred = trained_model.predict(X_test) }>)

  -- Combine into DataFrame
  combined_df = pyn(
    command = <{
from pandas import DataFrame
combined_df = DataFrame({"target": y_test, "prediction": y_pred})
    }>,
    serializer = ^arrow
  )

  -- Confusion matrix in R
  confusion_matrix = rn(
    command = <{ 
library(yardstick)
library(dplyr)
cm_obj = combined_df %>%
  mutate(target = as.factor(target), prediction = as.factor(prediction)) %>%
  conf_mat(truth = target, estimate = prediction)
confusion_matrix = as.data.frame(cm_obj$table)
    }>,
    serializer = ^json,
    deserializer = ^arrow
  )

  -- Accuracy score in Python
  accuracy = pyn(
    command = <{
from sklearn.metrics import accuracy_score
accuracy = accuracy_score(y_test, y_pred)
    }>,
    serializer = ^json,
  )

  -- Render Quarto report
  report = node(script = "src/report.qmd", runtime = Quarto)
}

-- Materialize
populate_pipeline(p, build = true, verbose=1)
pipeline_copy()
