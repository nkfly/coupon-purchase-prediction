#read in all the input data
cpdtr <- read.csv("./data/coupon_detail_train.csv", stringsAsFactors=FALSE)
cpltr <- read.csv("./data/coupon_list_train.csv", stringsAsFactors=FALSE)
cplte <- read.csv("./data/coupon_list_test.csv", stringsAsFactors=FALSE)
cpvtr <- read.csv("./data/coupon_visit_train.csv", stringsAsFactors=FALSE)
ulist <- read.csv("./data/user_list.csv", stringsAsFactors=FALSE)

#making of the train set of purchasing
train <- merge(cpdtr,cpltr)
train <- train[,c("COUPON_ID_hash","USER_ID_hash","ITEM_COUNT",
                  "GENRE_NAME","DISCOUNT_PRICE","PRICE_RATE",
                  "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
                  "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
                  "USABLE_DATE_BEFORE_HOLIDAY","ken_name","small_area_name")]

#To consider user prefecture, not complete
#userperf <- ulist[,c("USER_ID_hash", "PREF_NAME")]
#userperf$SAME_PERF <- 2
#names(userperf)[names(userperf)=="PREF_NAME"] <- "ken_name"
#train <- merge(train, userperf, all.x = TRUE)
#train[is.na(train$PREF_NAME)]$PREF_NAME <- 0
#train$ITEM_COUNT <- train$ITEM_COUNT + train$SAME_PERF
#train <- train[,c("COUPON_ID_hash","USER_ID_hash","ITEM_COUNT",
#                  "GENRE_NAME","DISCOUNT_PRICE","PRICE_RATE",
#                  "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
#                  "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
#                  "USABLE_DATE_BEFORE_HOLIDAY","ken_name","small_area_name")]

#making of the train set of viewing and purchasing
#left join by common columns: PURCHASEID_hash, USER_ID_hash
#If PURCHASEID_hash != "", then COUPON_ID_hash == VIEW_COUPON_ID_hash
#visit <- merge(cpvtr[,-c(2)],cpdtr[,-c(2)], all.x = TRUE)

#For testing whether COUPON_ID_hash == VIEW_COUPON_ID_hash:
#test3 <- view3[!is.na(view3$COUPON_ID_hash),]
#notequal <- test3[test3$COUPON_ID_hash != test3$VIEW_COUPON_ID_hash,]

#To check whether num(PURCHASEID_hash) == test3:
#test4 <- view3[view3$PURCHASEID_hash != "",]

#Some functions for future usage:
#sum(dataFrame$a == 5 & dataFrame$b > 3)
#uchar$VIEW_COUNT <- apply(uchar[,c('COUPON_ID_hash', 'USER_ID_hash')], 1, function(x) { sum(cpvtr$COUPON_ID_hash == x[1] & cpvtr$USER_ID_hash > x[2]) } )

#sadness try...(21, 35~42)
#visit <- visit[,-c(10)] #drop COUPON_ID_hash since it is a subset of VIEW_COUPON_ID_hash
#names(visit)[names(visit)=="VIEW_COUPON_ID_hash"] <- "COUPON_ID_hash"  
#train <- merge(visit,cpltr)
#train <- train[,c("COUPON_ID_hash","USER_ID_hash","ITEM_COUNT",
#                  "GENRE_NAME","DISCOUNT_PRICE","PRICE_RATE",
#                  "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
#                  "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
#                  "USABLE_DATE_BEFORE_HOLIDAY","ken_name","small_area_name")]


#combine the test set with the train
cplte$USER_ID_hash <- "dummyuser"
cplte$ITEM_COUNT <- NA
cpchar <- cplte[,c("COUPON_ID_hash","USER_ID_hash","ITEM_COUNT",
                   "GENRE_NAME","DISCOUNT_PRICE","PRICE_RATE",
                   "USABLE_DATE_MON","USABLE_DATE_TUE","USABLE_DATE_WED","USABLE_DATE_THU",
                   "USABLE_DATE_FRI","USABLE_DATE_SAT","USABLE_DATE_SUN","USABLE_DATE_HOLIDAY",
                   "USABLE_DATE_BEFORE_HOLIDAY","ken_name","small_area_name")]
train <- rbind(train,cpchar)
#NA imputation
train <- transform(train, ITEM_COUNT = as.numeric(ITEM_COUNT))
#train$ITEM_COUNT <- train$ITEM_COUNT * 20
train[is.na(train)] <- 1
#feature engineering
train$DISCOUNT_PRICE <- 1/log10(train$DISCOUNT_PRICE)
train$PRICE_RATE <- (train$PRICE_RATE*train$PRICE_RATE)/(100*100)
#convert the factors to columns of 0's and 1's
train <- cbind(train[,c(1,2,3)],model.matrix(~ -1 + .,train[,-c(1,2,3)],
                                                    contrasts.arg=lapply(train[,names(which(sapply(train[,-c(1,2,3)], is.factor)==TRUE))], contrasts, contrasts=FALSE)))
#feature engineering (binning the price into different buckets)
#train$DISCOUNT_PRICE <- cut(train$DISCOUNT_PRICE,breaks=c(-0.01,0,1000,10000,50000,100000,Inf),labels=c("free","cheap","moderate","expensive","high","luxury"))
#convert the factors to columns of 0's and 1's
#train <- cbind(train[,c(1,2,3)],model.matrix(~ -1 + .,train[,-c(1,2,3)]))


#separate the test from train
test <- train[train$USER_ID_hash=="dummyuser",]
test <- test[,-c(2, 3)] #delete second column or not select the second column
train <- train[train$USER_ID_hash!="dummyuser",]

#making viewing count data
view  <- cpvtr[cpvtr$PURCHASE_FLG==0,]
view  <- cpvtr[,c("VIEW_COUPON_ID_hash", "USER_ID_hash")]
names(view)[names(view)=="VIEW_COUPON_ID_hash"] <- "COUPON_ID_hash"
view$VIEW_COUNT <- 1
view <- aggregate(.~USER_ID_hash+COUPON_ID_hash, data=view,FUN=sum)
train <- merge(train, view, all.x = TRUE)
train[is.na(train)] <- 1
train$ITEM_COUNT <- train$ITEM_COUNT * train$VIEW_COUNT
train <- train[,-c(128)]

#data frame of user characteristics
#uchar <- aggregate(.~USER_ID_hash, data=train[,-1],FUN=mean) # 'data=train[,-1]' means exclude column 1
#uchar <- transform(train, ITEM_COUNT = as.numeric(ITEM_COUNT))
uitemcountmax <- aggregate(.~USER_ID_hash, data=train[,c(2,3)],FUN=max)
names(uitemcountmax)[names(uitemcountmax)=="ITEM_COUNT"] <- "MAX_BUY"
uitemcountmin <- aggregate(.~USER_ID_hash, data=train[,c(2,3)],FUN=min)
names(uitemcountmin)[names(uitemcountmin)=="ITEM_COUNT"] <- "MIN_BUY"
uitemcountsum <- aggregate(.~USER_ID_hash, data=train[,c(2,3)],FUN=sum)
names(uitemcountsum)[names(uitemcountsum)=="ITEM_COUNT"] <- "SUM_BUY"
uchar <- train
uchar[,-c(1,2,3)] <- uchar[,-c(1,2,3)] * uchar$ITEM_COUNT
uchar <- aggregate(.~USER_ID_hash, data=uchar[,-1],FUN=sum)
uchar[,-c(1,2)] <- uchar[,-c(1,2)] / uchar$ITEM_COUNT
uchar <- merge(uchar, uitemcountmax)
uchar <- merge(uchar, uitemcountmin)
#uchar <- merge(uchar, uitemcountsum)

#Weight Matrix: GENRE_NAME DISCOUNT_PRICE PRICE_RATE USABLE_DATE_ ken_name small_area_name
require(Matrix)
W <- as.matrix(Diagonal(x=c(rep(3,13), rep(1,1), rep(0.2,1), rep(0,9), rep(3,46), rep(3,54))))

#calculation of cosine similairties of users and coupons
score = as.matrix(uchar[,3:(ncol(uchar)-2)]) %*% W %*% t(as.matrix(test[,2:ncol(test)]))
#order the list of coupons according to similairties and take only first 10 coupons
uchar$PURCHASED_COUPONS <- do.call(rbind, lapply(1:nrow(uchar),FUN=function(i){
  first <- rep(test$COUPON_ID_hash[order(score[i,], decreasing = TRUE)][1], each=1) #uchar[i,"MAX_BUY"]
  total <- append(first, test$COUPON_ID_hash[order(score[i,], decreasing = TRUE)][2:10])
  purchased_cp <- paste(total,collapse=" ")
  return(purchased_cp)
}))

#make submission
uchar <- merge(ulist, uchar, all.x=TRUE)
submission <- uchar[,c("USER_ID_hash","PURCHASED_COUPONS")]
write.csv(submission, file="cosine_sim_weighted_3.csv", row.names=FALSE)
