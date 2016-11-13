#############################################################################
#title: "Modeling for Predicting Hospital Readmissions, Hack K-State, 2016"##
#author: "Youliang Yu"                                                     ##
#date: "Nov. 11, 2016"                                                     ##      
#############################################################################

rm(list=ls()) 
#build models and ensemble")
library(caret)
library(data.table)  
library(xgboost)
library(ranger)
library(Metrics)
library(doMC)
library(glmnet)
 
train <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
test <- fread('data/Challenge_1_Validation.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
train <- train[!is.na(train$readmitted),]
trainID <- train$patient_nbr;y = as.integer(as.factor(train$readmitted))-1
train$encounter_id <- train$patient_nbr <- train$readmitted  <- NULL
testID <- test$patient_nbr;test$encounter_id <- test$patient_nbr <- NULL

#remove constant vars
cst_vars <- union(names(train)[apply(train, 2, function(x) length(unique(x))==1)],
                  names(test)[apply(test, 2, function(x) length(unique(x))==1)])

for (f in cst_vars){train[[f]] <- NULL;test[[f]] <- NULL}
#medi_vars <- names(train[,c(23:40)]) 

#factorize cate variables
fact_vars <- names(test)[sapply(test, is.character)] #;names(train)[sapply(train, is.character)]
for (f in fact_vars) {
  if (class(train[[f]])=="character") {
    levels <- unique(c(train[[f]], test[[f]]))
    train[[f]] <- as.integer(factor(train[[f]], levels=levels))
    test[[f]]  <- as.integer(factor(test[[f]],  levels=levels))
  }
}

# treat NA
# get features with all NA(>99.99%)
# na_var <- names(train)[apply(train, 2, function(x)  sum(is.na(x))/nrow(train)>0.9999)]
train$NAnbr <- apply(train,1, function(x) sum(is.na(x)))
test$NAnbr <- apply(test,1, function(x) sum(is.na(x)))
train[is.na(train)] <- 0;test[is.na(test)] <- 0

#create stratified 5 folds for CV
set.seed(1229)
fold5 <- createFolds(y, k = 5, list = T)
xfolds <- array(0, c(length(y), 2))
xfolds[,1] <- trainID # columb 1 = trainID
for (k in seq(fold5)) {xfolds[fold5[[k]],2] <- k}# column 2 gets the {1,2,3,4,5} id assigned
colnames(xfolds) <- c("ID", "fold5"); xfolds <- as.data.frame(xfolds)
nfolds <- length(unique(xfolds$fold5))

# start building model
modelNum <- 20;i=0
mtrain <- array(0, c(nrow(train),modelNum))
mtest <- array(0, c(nrow(test),modelNum))

#XGB 1
i=i+1;
param <- list(booster ="gbtree", objective = 'binary:logistic', eval_metric = 'rmse',
              nthread = 6,eta = 0.02, colsample_bytree = 0.5, subsample = 0.8, max_depth = 6, min_child_weight=11)
dtrain <- xgb.DMatrix(as.matrix(cbind(train)), label = y)
bst.cv = xgb.cv(param=param, data = dtrain, nfold = 5, nrounds = 5000, early.stop.round = 80, set.seed(1229))
tmp <- bst.cv$test.rmse.mean; n=which(tmp==min(tmp))[1]#418
# loop over folds
for (j in 1:nfolds){ 
  indexTrain <- which(xfolds$fold5 != j)
  indexValid <- which(xfolds$fold5 == j)
  x0d <- xgb.DMatrix(as.matrix(train[indexTrain,]),label = y[indexTrain])
  x1d <- xgb.DMatrix(as.matrix(train[indexValid,]),label = y[indexValid])
  set.seed(1229)
  clf <- xgb.train(params=param, data=x0d, nround = n)
  mtrain[indexValid,i] <- predict(clf, as.matrix(train[indexValid,]))
  cat(rmse(y[indexValid],mtrain[indexValid,i]))
}
cat(rmse(y,mtrain[,i]))
#full version
set.seed(1229)
x0d <- xgb.DMatrix(as.matrix(train), label = y)
clf <- xgb.train(params=param, data=x0d, nround = as.integer(n/0.8))
mtest[,i] <- predict(clf, as.matrix(test))

#ranger 1
i = i+1;
#  loop over folds
for (j in 1:nfolds){
  indexTrain <- which(xfolds$fold5 != j)
  indexValid <- which(xfolds$fold5 == j)
  ranger.model <- ranger(dependent.variable.name = "y", 
                         data = cbind(y,train)[indexTrain,],
                         mtry = 30, #probability = T,
                         num.trees = 250,
                         write.forest = T,
                         min.node.size = 1,
                         set.seed(1229))
  pred_valid <- predict(ranger.model, train[indexValid,])$predictions
  mtrain[indexValid,i] <- pred_valid
  cat(rmse(y[indexValid],pred_valid)) 
}
cat(rmse(y,mtrain[,i])) # [1] 0.42110
# full version
ranger.model <- ranger(dependent.variable.name = "y", 
                       data = cbind(y,train),
                       mtry = 30, 
                       num.trees = 300,
                       write.forest = T,
                       min.node.size = 1,
                       seed = 1229) 
mtest[,i] <- predict(ranger.model, test)$predictions
#rm(ranger.model);rm(pred_full);gc();

# glmnet 1
# for (f in na_var){train[[f]] <- NULL};test[[f]] <- NULL} #rm variables most with NAs
lambda <-10^seq(-4,-1,0.02) 
registerDoMC(cores=7)
i=i+1
for (j in 1:nfolds){  
  indexTrain <- which(xfolds$fold5 != j)
  indexValid <- which(xfolds$fold5 == j)  
  clf <- cv.glmnet(y=y[indexTrain], x=as.matrix(train[indexTrain,]),
                   family="binomial",type.measure="mse", nfolds =4,parallel=TRUE,lambda=lambda)
  qplot(clf$lambda,clf$cvm)
  pred_valid <- predict(clf,newx=as.matrix(train[indexValid,]), s="lambda.min",type="response")
  mtrain[indexValid,i] <- pred_valid
  cat(rmse(y[indexValid],mtrain[indexValid,i])) #0.4848158
}
cat(rmse(y,mtrain[,i]))
#full version
clf <- cv.glmnet(y=y,x=as.matrix(train),
                 family="binomial",type.measure="auc", nfolds = 5,parallel=TRUE,lambda=lambda)
qplot(clf$lambda,clf$cvm)
mtest[,i] <- predict(clf,newx=as.matrix(test), s="lambda.min",type="response")

#one-hot-encode
encode_vars <- names(train)[apply(rbind(train), 2, function(x) length(unique(x))<100)]
for (f in intersect(names(train),union(encode_vars,fact_vars))){
  dummyfact <- as.factor(c(-100000,train[[f]],test[[f]]))
  temp <- model.matrix(~dummyfact)
  k=0
  for (j in 2:ncol(temp)){
    colnames(temp)[j] <- paste0(f,"Dummy",k)
    k <- k+1
  }
  train <- cbind(train,temp[2:(nrow(train)+1),-1])
  test <- cbind(test,temp[(nrow(train)+2):nrow(temp),-1])
  rm(temp);rm(dummyfact);gc()
} 

#XGB 2
i=i+1;
param <- list(booster ="gbtree", objective = 'binary:logistic', eval_metric = 'rmse',
              nthread = 6,eta = 0.01, colsample_bytree = 0.4, subsample = 0.8, max_depth = 6, min_child_weight=11)
dtrain <- xgb.DMatrix(as.matrix(cbind(train)), label = y)
bst.cv = xgb.cv(param=param, data = dtrain, nfold = 5, nrounds = 5000, early.stop.round = 80, set.seed(1229))
tmp <- bst.cv$test.rmse.mean; n=which(tmp==min(tmp))[1]
# loop over folds
for (j in 1:nfolds){ 
  indexTrain <- which(xfolds$fold5 != j)
  indexValid <- which(xfolds$fold5 == j)
  x0d <- xgb.DMatrix(as.matrix(train[indexTrain,]),label = y[indexTrain])
  x1d <- xgb.DMatrix(as.matrix(train[indexValid,]),label = y[indexValid])
  set.seed(1229)
  clf <- xgb.train(params=param, data=x0d, nround = n)
  mtrain[indexValid,i] <- predict(clf, as.matrix(train[indexValid,]))
  cat(rmse(y[indexValid],mtrain[indexValid,i]))
}
cat(rmse(y,mtrain[,i]))
#full version
set.seed(1229)
x0d <- xgb.DMatrix(as.matrix(train), label = y)
clf <- xgb.train(params=param, data=x0d, nround = as.integer(n/0.8))
mtest[,i] <- predict(clf, as.matrix(test))

#ranger 2
i = i+1;
ranger.model <- ranger(dependent.variable.name = "y", 
                         data = cbind(y,train),
                         mtry = 30, 
                         num.trees = 300,
                         write.forest = T,
                         min.node.size = 1,
                         seed = 1229)
pred_full <- predict(ranger.model, test)$predictions
mtest[,i] <- pred_full
#  loop over folds
for (j in 1:nfolds){
  indexTrain <- which(xfolds$fold5 != j)
  indexValid <- which(xfolds$fold5 == j)
  ranger.model <- ranger(dependent.variable.name = "y", 
                         data = cbind(y,train)[indexTrain,],
                         mtry = 30, #probability = T,
                         num.trees = 250,
                         write.forest = T,
                         min.node.size = 1,
                         set.seed(1229))
  pred_valid <- predict(ranger.model, train[indexValid,])$predictions
  mtrain[indexValid,i] <- pred_valid
  cat(rmse(y[indexValid],pred_valid)) 
}
cat(rmse(y,mtrain[,i]))

# glmnet 2
# clean data again for numeric variables...
train <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
test <- fread('data/Challenge_1_Validation.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
train <- train[!is.na(train$readmitted),] # remove NA label samples
trainID <- train$patient_nbr;y = as.integer(as.factor(train$readmitted))-1
train$encounter_id <- train$patient_nbr <- train$readmitted  <- NULL
testID <- test$patient_nbr;test$encounter_id <- test$patient_nbr <- NULL
 
#apply(train, 2, function(x) sum(is.na(x))/nrow(train)*100)
cst_vars <- union(names(train)[apply(train, 2, function(x) length(unique(x))==1)],
                  names(test)[apply(test, 2, function(x) length(unique(x))==1)])
for (f in cst_vars){train[[f]] <- NULL; test[[f]] <- NULL}
train <- train[, !names(train) %in% fact_vars];train$readmitted <- NULL
test <- test[, !names(test) %in% fact_vars];test$readmitted <- NULL
 
i=i+1
lambda <-10^seq(-3,-1.5,0.005) 
registerDoMC(cores=7)
for (j in 1:nfolds){  
    indexTrain <- which(xfolds$fold5 != j)
    indexValid <- which(xfolds$fold5 == j)  
    clf <- cv.glmnet(y=y[indexTrain], x=as.matrix(train[indexTrain,]),
                     family="binomial",type.measure="auc", nfolds =4,parallel=TRUE,lambda=lambda)
    qplot(clf$lambda,clf$cvm)
    pred <- predict(clf,newx=as.matrix(train[indexValid,]), s="lambda.min",type="response")
    mtrain[indexValid,i] <- pred
    cat(rmse(y[indexValid],mtrain[indexValid,i])) 
}
cat(rmse(y,mtrain[,i]))
#full version  
clf <- cv.glmnet(y=y,x=as.matrix(train),
                 family="binomial",type.measure="auc", nfolds = 4,parallel=TRUE,lambda=lambda)
qplot(clf$lambda,clf$cvm)
mtest[,i] <- predict(clf,newx=as.matrix(test), s="lambda.min",type="response")

# glm stacking
#lambda <-10^seq(-5,-1.5,0.01) 
#clf <- cv.glmnet(y=y,x=as.matrix(mtrain[,1:6]),
#                 family="binomial",type.measure="auc", nfolds = 4,parallel=TRUE,lambda=lambda)
#qplot(clf$lambda,clf$cvm)
# stacking not work so well for this dataset, not as good as simple averaging~

#apply(mtrain[,1:6], 2, function(x) auc(y,x)) #auc
apply(mtrain[,1:6], 2, function(x) mse(y,x)) #auc
pred_train <- (4*mtrain[,1]+1*mtrain[,2]+1*mtrain[,3]+8*mtrain[,4]+2*mtrain[,5])/16;mse(y,pred_train)
sum(1-abs(y-pred_train)/2)/length(pred) 
#82.3% prediction correct

#pred <- as.integer(pred_train>0.756)
 
#submission 
pred_test <- (4*mtest[,1]+1*mtest[,2]+1*mtest[,3]+8*mtest[,4]+2*mtest[,5])/16
submission <- data.frame(ID=testID, readmitted= as.numeric(format(pred_test,digits = 16,scientific = FALSE)))
#head(submission)
write.csv(submission, "validation_readmitted.csv", row.names=FALSE)
  