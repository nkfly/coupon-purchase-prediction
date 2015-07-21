#read in all the input data
cpdtr <- read.csv("./data/coupon_detail_train.csv")
cpltr <- read.csv("./data/coupon_list_train.csv")
cplte <- read.csv("./data/coupon_list_test.csv")
ulist <- read.csv("./data/user_list.csv")

#making of the train set
train <- merge(cpdtr,cpltr)
train <- train[,c("COUPON_ID_hash","USER_ID_hash","ITEM_COUNT",
                  "GENRE_NAME","DISCOUNT_PRICE",
                  "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
                  "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
                  "USABLE_DATE_BEFORE_HOLIDAY","ken_name","small_area_name")]
#combine the test set with the train
cplte$USER_ID_hash <- "dummyuser"
cplte$ITEM_COUNT <- "dummycount"
cpchar <- cplte[,c("COUPON_ID_hash","USER_ID_hash","ITEM_COUNT",
                   "GENRE_NAME","DISCOUNT_PRICE",
                   "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
                   "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
                   "USABLE_DATE_BEFORE_HOLIDAY","ken_name","small_area_name")]

train <- rbind(train,cpchar)
#NA imputation
train[is.na(train)] <- 1
#feature engineering (binning the price into different buckets)
train$DISCOUNT_PRICE <- cut(train$DISCOUNT_PRICE,breaks=c(-0.01,0,1000,10000,50000,100000,Inf),labels=c("free","cheap","moderate","expensive","high","luxury"))
#convert the factors to columns of 0's and 1's
train <- cbind(train[,c(1,2,3)],model.matrix(~ -1 + .,train[,-c(1,2,3)]))

#separate the test from train
test <- train[train$USER_ID_hash=="dummyuser",]
test <- test[,-c(2, 3)] #delete second column or not select the second column
train <- train[train$USER_ID_hash!="dummyuser",]

#data frame of user characteristics
#uchar <- aggregate(.~USER_ID_hash, data=train[,-1],FUN=mean) # 'data=train[,-1]' means exclude column 1
uchar <- transform(train, ITEM_COUNT = as.numeric(ITEM_COUNT))
uchar[,-c(1,2,3)] <- uchar[,-c(1,2,3)] * uchar$ITEM_COUNT
uchar <- aggregate(.~USER_ID_hash, data=uchar[,-1],FUN=sum)
uchar[,-c(1,2)] <- uchar[,-c(1,2)] / uchar$ITEM_COUNT

#calculation of cosine similairties of users and coupons
score = as.matrix(uchar[,3:ncol(uchar)]) %*% t(as.matrix(test[,2:ncol(test)]))
#order the list of coupons according to similairties and take only first 10 coupons
uchar$PURCHASED_COUPONS <- do.call(rbind, lapply(1:nrow(uchar),FUN=function(i){
  purchased_cp <- paste(test$COUPON_ID_hash[order(score[i,], decreasing = TRUE)][1:10],collapse=" ")
  return(purchased_cp)
}))

#make submission
uchar <- merge(ulist, uchar, all.x=TRUE)
submission <- uchar[,c("USER_ID_hash","PURCHASED_COUPONS")]
write.csv(submission, file="cosine_sim.csv", row.names=FALSE)
