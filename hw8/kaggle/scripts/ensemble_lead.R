## Clear Workspace
rm(list=ls())

## Load libraries
library(caret)
library(xgboost)
library(readr)
library(dplyr)
library(tidyr)
library(ranger)
library(e1071)

## Data
df_x <- read_csv("data/train_predictors.txt", col_names = FALSE)
df_y <- read_csv("data/train_labels.txt", col_names = FALSE)
df_x_final <- read_csv("data/test_predictors.txt", col_names = FALSE)

df_sub <- data.frame(read_csv("data/sample_submission.txt", col_names = TRUE))

df_x <- data.frame(df_x)
df_y <- data.frame(df_y)
df_x_final <- data.frame(df_x_final)
names(df_y) <- "Y"

# Bind together
df <- cbind(df_y, df_x)

rm(df_x, df_y)

## Split dataset into test and train
set.seed(123)
sample_id <- sample(row.names(df), size = nrow(df) * 0.8, replace = FALSE)

df_train <- df[row.names(df) %in% sample_id, ]
df_test <- df[!row.names(df) %in% sample_id, ]

# Omit missings
df_train <- na.omit(df_train)

# xgboost
#--------
min.error.idx <- 40

param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6,    # maximum depth of tree 
              "eta" = 0.5,    # step size shrinkage 
              "gamma" = 2,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.8,  # minimum sum of instance weight needed in a child
              "scale_pos_weight" = 45,
              "max_delta_step" = 0
)

bst <- xgboost(param=param,
               data=as.matrix(df_train %>% select(-Y)),
               label=df_train$Y, 
               nrounds=min.error.idx,
               verbose=0)

# Random forest
#--------------
# Modelling
set.seed(1234)
df_train$Y <- as.factor(df_train$Y)
rf <- ranger(Y ~ ., df_train, probability=TRUE)

rf.tune = csrf(
  Y ~ .,
  training_data = df_train,
  test_data = df_test,
  params1 = list(num.trees = 25, mtry=10),
  params2 = list(num.trees = 50, mtry=20)
)

sqrt(length(df_train))
fit.rf = ranger(
  Species ~ ., data = iris,
  num.trees = 200
)




# SVM
#----
library(e1071)
svm_model <- svm(Y ~ ., data=df_train, probability=TRUE)

svm_tune <- tune(svm, train.x=x, train.y=y, 
                 kernel="radial", ranges=list(cost=10^(-1:2), gamma=c(.5,1,2)))

print(svm_tune)

#svm_model_after_tune <- svm(Species ~ ., data=iris, kernel="radial", cost=1, gamma=0.5)
#summary(svm_model_after_tune)


pred <- predict(svm_model1,x)
system.time(pred <- predict(svm_model1,x))



# Predictions
preds = predict(rf, data.matrix(df_test[, 2:length(df_test)]), type = "prob")





# xgboos prediction
preds = predict(bst, data.matrix(df_test[, 2:length(df_test)]), type = "prob")
label = round(preds)
conf_matr <- table(df_test$Y, label)

# random forest prediction
preds = predict(rf, data.matrix(df_test[, 2:length(df_test)]))
label = round(preds$predictions[, 2])
conf_matr <- table(df_test$Y, label)

# svm prediction
preds = predict(svm_model, data.matrix(df_test[, 2:length(df_test)]), type = 'prob')
label = round(preds$predictions[, 2])
conf_matr <- table(df_test$Y, label)

# Evaluation
p <- conf_matr[4] / (conf_matr[4] + conf_matr[3])
r <- conf_matr[4] / (conf_matr[4] + conf_matr[2])

F1 <- 2 * (p * r) / (p + r)
F1












# Predictions

# Predictions
preds = predict(bst, data.matrix(df_x_final))
label = round(preds)
df_sub <- data.frame(1:length(label), label)
names(df_sub) <- c('index', 'label')
write_csv(format(df_sub, digits=0), path = "data/submission.txt")


