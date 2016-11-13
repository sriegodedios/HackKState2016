#############################################################################
#title: "Modeling for Predicting Hospital Readmissions, Hack K-State, 2016"##
#author: "Youliang Yu"                                                     ##
#date: "Nov. 11, 2016"                                                     ##      
#############################################################################

rm(list=ls())
#load data
library(caret)
library(data.table)  
train <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
#test <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)

#get tsne features
train <- train[!is.na(train$readmitted),] # remove NA label samples
y = as.integer(as.factor(train$readmitted))-1;trainID <- train[, 2]
train <- train[,-c(1,2)] # remove IDs
#apply(train, 2, function(x) sum(is.na(x))/nrow(train)*100)
cst_vars <- names(train)[apply(train, 2, function(x) length(unique(x))==1)]; for (f in cst_vars){train[[f]] <- NULL} 
train$readmitted <- y; medi_vars <- names(train[,c(23:40)]) 

for(f in names(train)) { 
  if(is.character(train[[f]])) {
    #    levels <- unique(test[[f]])
    #    target.means <- unlist(lapply(levels, function(x) x=mean(train[,"readmitted"][train[,f]==x],na.rm = T)))
    #    names(target.means) <- levels
    #    tmp <- rep(NA, nrow(test))
    #    tmp[!is.na(test[[f]])] <- unlist(lapply(test[[f]][!is.na(test[[f]])], function(x) x = target.means[[x]]))
    #    test[[f]] <- tmp
    temp <- rep(NA, nrow(train)) 
    for(i in 1:5) {
      ids.1 <- -seq(i, nrow(train), by=5)
      ids.2 <- seq(i, nrow(train), by=5)
      levels <- unique(train[ids.2,f])
      target.means <- unlist(lapply(levels, function(x) x=mean(train[ids.1,"readmitted"][train[ids.1,f]==x],na.rm = T)))
      names(target.means) <- levels
      temp[ids.2][!is.na(train[ids.2,f])] <- unlist(lapply(train[ids.2,f][!is.na(train[ids.2,f])], function(x) x = target.means[[x]]))
    }
    train[[f]] <- temp
  }
}

train[is.na(train)] <- 0
train$readmitted <- NULL
  
library(Rtsne)
tsne_targetmean<- Rtsne(as.matrix(rbind(train)), check_duplicates =FALSE, PCA =T, verbose=TRUE,
                  perplexity=30, theta=0.5, dims=2, max_iter=800)
#palette(c("red", "blue"))
#target = factor(y)
#qplot(tsne_targetmean$Y[,1],tsne_targetmean$Y[,2], xlab="Y1", ylab="Y2") + aes(shape = target)+aes(colour = target)+ scale_shape(solid = FALSE) 

 
cat("Build model and ensemble")
library(xgboost)
library(ranger)
library(Metrics)

train <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
#test <- fread('data/Challenge_1_Testing.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
train <- train[!is.na(train$readmitted),]
trainID <- train$patient_nbr;y = as.integer(as.factor(train$readmitted))-1
train$encounter_id <- train$patient_nbr <- train$readmitted  <- NULL
#test$encounter_id <- test$patient_nbr <- NULL

#remove constant vars
cst_vars <- names(train)[apply(train, 2, function(x) length(unique(x))==1)]
for (f in cst_vars){train[[f]] <- NULL} #;test[[f]] <- NULL}
medi_vars <- names(train[,c(23:40)]) 

#factorize cate variables
fact_vars <- names(train)[sapply(train, is.character)]
for (f in fact_vars) {
  if (class(train[[f]])=="character") {
    levels <- unique(c(train[[f]]))#, test[[f]]))
    train[[f]] <- as.integer(factor(train[[f]], levels=levels))
#    test[[f]]  <- as.integer(factor(test[[f]],  levels=levels))
  }
}

#impute NA
train$NAnbr <- apply(train,1, function(x) sum(is.na(x)))
train[is.na(train)] <- 0#;test[is.na(test)] <- 0

#create stratified 5 folds for CV
set.seed(1229)
fold5 <- createFolds(y, k = 5, list = T)
xfolds <- array(0, c(length(y), 2))
xfolds[,1] <- trainID # columb 1 = trainID
for (k in seq(fold5)) {xfolds[fold5[[k]],2] <- k}# column 2 gets the {1,2,3,4,5} id assigned
colnames(xfolds) <- c("ID", "fold5"); xfolds <- as.data.frame(xfolds)
nfolds <- length(unique(xfolds$fold5))

#### building models ####
modelNum <- 4;i=0
mtrain <- array(0, c(nrow(train),modelNum))
#mtest <- array(0, c(nrow(test),length(modelNum)))

#XGB 1
i=i+1;
param <- list(booster ="gbtree", objective = 'binary:logistic', eval_metric = 'rmse',
              nthread = 6,eta = 0.02, colsample_bytree = 0.5, subsample = 0.8, max_depth = 6, min_child_weight=11)
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
rmse(y,mtrain[,i])
#full version
set.seed(1229)
x0d <- xgb.DMatrix(as.matrix(train), label = y)
clf <- xgb.train(params=param, data=x0d, nround = as.integer(n/0.8))
#mtest[,i] <- predict(clf, as.matrix(test))

#one-hot-encode
encode_vars <- names(train)[apply(rbind(train), 2, function(x) length(unique(x))<100)]
for (f in union(encode_vars,fact_vars)){ 
  dummyfact <- as.factor(c(-100000,train[[f]]))#,testx[[f]]))
  temp <- model.matrix(~dummyfact)
  k=0
  for (j in 2:ncol(temp)){
    colnames(temp)[j] <- paste0(f,"Dummy",k)
    k <- k+1
  }
  train <- cbind(train,temp[2:(nrow(train)+1),-1])
#  test <- cbind(test,temp[(nrow(test)+2):nrow(temp),-1])
  rm(temp);rm(dummyfact);gc()
}
#for (f in union(encode_vars,fact_vars)){train[[f]]<-NULL}#;test[[f]]<-NULL}
#0.01, train-rmse:0.402431+0.000736	test-rmse:0.419231+0.003265 ***best*** 

#ranger 1
i = i+1;
ranger.model <- ranger(dependent.variable.name = "y", 
                         data = cbind(y,train),
                         mtry = 30, 
                         num.trees = 250,
                         write.forest = T,
                         min.node.size = 1,
                         seed = 1229) 
#  pred_full <- predict(ranger.model, test)$predictions
#  mtest[,i] <- pred_full
#  rm(ranger.model);rm(pred_full);gc();
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
rmse(y,mtrain[,i]) # [1] 0.42110

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
rmse(y,mtrain[,i])
#full version
set.seed(1229)
x0d <- xgb.DMatrix(as.matrix(train), label = y)
clf <- xgb.train(params=param, data=x0d, nround = as.integer(n/0.8))
#mtest[,i] <- predict(clf, as.matrix(test))

# glmnet
# clean data again for numeric variables...
train <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
#test <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,na.strings=c("?","No","NO","None",""),data.table= FALSE)
train <- train[!is.na(train$readmitted),] # remove NA label samples
y = as.integer(as.factor(train$readmitted))-1;trainID <- train[, 2]
train <- train[,-c(1,2)] # remove IDs
#apply(train, 2, function(x) sum(is.na(x))/nrow(train)*100)
cst_vars <- names(train)[apply(train, 2, function(x) length(unique(x))==1)]; for (f in cst_vars){train[[f]] <- NULL} 
train$readmitted <- y; #medi_vars <- names(train[,c(23:40)]) 
train <- train[, !names(train) %in% fact_vars];train$readmitted <- NULL
#na_vars <- names(train)[apply(train, 2, function(x) sum(is.na(x))/nrow(train)*100 == 0)]

library(doMC)
library(glmnet)
lambda <-10^seq(-8,-1,0.1) 
registerDoMC(cores=7)
i=i+1
for (j in 1:nfolds){  
    indexTrain <- which(xfolds$fold5 != j)
    indexValid <- which(xfolds$fold5 == j)  
    clf <- cv.glmnet(y=y[indexTrain], x=as.matrix(mtrain[indexTrain,]),
                     family="binomial",type.measure="mse", nfolds =4,parallel=TRUE,lambda=lambda)
    qplot(clf$lambda,clf$cvm)
    pred <- predict(clf,newx=as.matrix(mtrain[indexValid,]), s="lambda.min",type="response")
    mtrain[indexValid,i] <- pred
    cat(rmse(y[indexValid],mtrain[indexValid,i])) #0.4848158
#    rm(indexTrain);rm(indexValid);rm(clf);rm(pred);gc()
}
rmse(y,mtrain[,i])
#full version
pred <- matrix(0, nrow(test))
clf <- cv.glmnet(y=y,x=as.matrix(mtrain),
                 family="binomial",type.measure="auc", nfolds = 5,parallel=TRUE,lambda=lambda)
pred <- predict(clf,newx=as.matrix(mtrain), s="lambda.min",type="response")

rmse(y,pred)     
rmse(y,(2*mtrain[,1]+1*mtrain[,2]+3*mtrain[,3])/6)

apply(mtrain, 2, function(x) rmse(y,x))
# level 1 stacking
set.seed(1229)
#idx <- sample(1:nrow(train), nrow(train), replace =FALSE)
#train <- train[idx,]; y <- y[idx]
dtrain <- xgb.DMatrix(as.matrix(cbind(mtrain)), label = y)
param <- list(booster ="gbtree", objective = 'binary:logistic', eval_metric = 'rmse',
              nthread = 6,eta = 0.01, colsample_bytree = 0.4, subsample = 0.8, max_depth = 6, min_child_weight=11)
bst.cv = xgb.cv(param=param, data = dtrain, nfold = 5, nrounds = 5000, early.stop.round = 20)
tmp <- bst.cv$test.rmse.mean; n=which(tmp==min(tmp))[1]

#[716]	train-rmse:0.407825+0.000765	test-rmse:0.419664+0.003077
#[437]	train-rmse:0.402716+0.000767	test-rmse:0.419333+0.003904
#no dummy [917]	train-rmse:0.403022+0.000767	test-rmse:0.419341+0.003321
#tmp <- bst.cv$test.rmse.mean; n=which(tmp==min(tmp))[1];n
#bst <- xgb.train(params=param, data=dtrain, nround = as.integer(n/0.8))
#pred <- predict(bst, as.matrix(testx)) 