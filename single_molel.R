cat("hospital readmission data explore")
cat("By Youliang Yu")
cat("Nov 11, 2016")

library(caret)  
library(data.table) 
#library(bit64)
library(xgboost)
library(Metrics)
library(gtools)

setwd("/home/youliang/computing/hackingkstate/challenge1") 
#cat("first look at the train data...")
#train <- fread('data/Challenge_1_Training.csv')
#cat("missing value specified as (No,NO,None,?)")
#cat("seems a lot missing value, need to figure out how to deal with them, impute 0 as in the first model")

train <- fread('data/Challenge_1_Training.csv',header =TRUE,stringsAsFactors = FALSE,
               na.strings=c("?","No","NO","None",""),data.table= FALSE)
y <- train[!is.na(train$readmitted),50]
y <- as.integer(as.factor(y))-1
trainx <- train[!is.na(train$readmitted),-c(1,2)]
trainx[["readmitted"]] <- as.integer(as.factor(trainx$readmitted))-1

char_vars <- colnames(trainx)[sapply(trainx, is.character)]

# replace var with target mean
for(var in char_vars) {
  #  if(is.character(x.test[[var]])) {
  #    target.mean <- trainx[, list(pr=mean(target)), by=eval(var)]
  #    x.test[[var]] <- target.mean$pr[match(x.test[[var]], target.mean[[var]])] 
  temp <- rep(NA, nrow(trainx))
  print(var) 
  for(i in 1:4) {   
    ids.1 <- -seq(i, nrow(trainx), by=4)
    ids.2 <- seq(i, nrow(trainx), by=4)
    levels <- unique(trainx[ids.2,var])
    target.means <- unlist(lapply(levels, function(x) x=mean(trainx[ids.1,"readmitted"][trainx[ids.1,var]==x],na.rm = T)))
    names(target.means) <- levels
    temp[ids.2][!is.na(trainx[ids.2,var])] <- unlist(lapply(trainx[ids.2,var][!is.na(trainx[ids.2,var])], function(x) x = target.means[[x]]))
  }
  trainx[[var]] <- temp
  #  }
}

# factorize
for (f in names(trainx)) {
  if (class(trainx[[f]])=="character") {
    levels <- unique(c(trainx[[f]]))
    trainx[[f]] <- as.integer(factor(trainx[[f]], levels=levels)) 
  }
}

# get features gives too much NA(>9999%)
#apply(trainx, 2, function(x)  sum(is.na(x))/nrow(trainx))
na_var <- names(trainx)[apply(trainx, 2, function(x)  sum(is.na(x))/nrow(trainx)>0.99999)]
for (f in na_var){trainx[[f]] <- NULL}

# impute NA
trainx[is.na(trainx)] <- 0
# apply(trainx,2,class)

# set 10% holdout
set.seed(1229)
idx <- sample(1:nrow(trainx), 0.1*nrow(trainx), replace =FALSE)
testx <- trainx[idx,]
trainx <- trainx[-idx,]
y <- as.integer(as.factor(y))-1
testy <- y[idx];trainy <- y[-idx]
# set 10% holdout ends

# adding 2-way interaction
cmb <- combinations(n=length(char_vars), r=2, v=char_vars)
for(i in 1:nrow(cmb)) {
  trainx[[paste0(cmb[i,1], cmb[i,2])]] <- paste(trainx[[cmb[i,1]]], trainx[[cmb[i,2]]]) 
}
for (f in names(trainx)) {
  if (class(trainx[[f]])=="character") {
    levels <- unique(c(trainx[[f]]))
    trainx[[f]] <- as.integer(factor(trainx[[f]], levels=levels)) 
  }
} 
# adding 2-way interaction ends

#xgb model
set.seed(1229)

dtrain <- xgb.DMatrix(as.matrix(cbind(rbind(trainx,testx)[,-ncol(trainx)],)), label = rbind(trainx,testx)[,ncol(trainx)])
param <- list(booster ="gbtree", objective = 'binary:logistic', eval_metric = 'rmse',
              nthread = 6,eta = 0.05, colsample_bytree = 1, subsample = 0.8, max_depth = 6, min_child_weight=11)

bst.cv = xgb.cv(param=param, data = dtrain, nfold = 10, nrounds = 1000, early.stop.round = 15)
# basic model CV colsample=1, [120]	train-rmse:0.396306+0.001360	test-rmse:0.421042+0.004926
#                colsample=1,subsample=0.8,[93]	train-rmse:0.397728+0.000859	test-rmse:0.420347+0.003593
#                colsample=1,subsample=0.8,max_depth=6,[104]	train-rmse:0.395256+0.000949	test-rmse:0.420451+0.003026
#                colsample=1,subsample=0.8,max_depth=6,min_child_weight=11,[106]	train-rmse:0.402792+0.000956	test-rmse:0.420202+0.002904
#                                                                 10 folds,[117]	train-rmse:0.402395+0.000709	test-rmse:0.420096+0.006663

# target-mean comparable

bst <- xgb.train(params=param, data=dtrain, nround = 120)
pred <- predict(bst, as.matrix(testx))
#plot(pred)
rmse(testy,pred)
#print(pred <- predict(bst, as.matrix(testx[1,])))

 