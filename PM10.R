library(MPV)
library(olsrr)
library(glmnet)
library(ggpubr)
library(psych)
data=read.csv('C:/Users/user/OneDrive/data.csv',header=T)[,c(1,2,3,4,5,6,8,10,11)]
time = seq.Date(from = as.Date("2015/01/01",format = "%Y/%m/%d"), 
                by = "month", length.out = nrow(data))
data = cbind(time,data)
plot(x=data$time,y=data$PM10,type='l',xlab = '',ylab='PM10',
     main='Variations of monthly PM10 at the monitoring stations',col='red')
points(x=data$time,y=data$PM10,pch=16,col='red')
data=data[,-1]
pairs.panels(data,method = "pearson",hist.col = "#00AFBB",density = TRUE,ellipses = TRUE)
std_data=as.data.frame(scale(data))

set.seed(123)
train.index = sample(x=1:nrow(std_data), size=ceiling(0.8*nrow(std_data)))

train = std_data[train.index, ]
test = std_data[-train.index, ]

Model=lm(PM10 ~ .,data=train)
summary(Model)

ols_vif_tol(Model)
X=as.matrix(train[,-6])
lambda=eigen(t(X)%*%X)$values
k=max(lambda)/min(lambda)
k

k1=ols_step_best_subset(Model)
k1
cat("Predictors: ", k1$predictors[k1$cp == min(k1$cp)])
model1=lm(PM10~CO+NO+SO2+Temp+RH, train)
summary(model1)

full=lm(PM10 ~ ., data = train)
null=lm(PM10 ~ 1, data = train) 
forward.lm=step(null, scope = list(lower=null,upper=full), direction="forward",test="F") 

model2=lm(PM10~CO+NO+NO2+SO2+Temp+RH, train)
summary(model2)

#Table1=as.data.frame(cbind(model1$residuals,hatvalues(model1),(model1$residuals/(1-hatvalues(model1)))^2))
#colnames(Table1)=c('e_i','h_ii','(e_i/1-h_ii)^2')
PRESS(model1)
#PRESS(model2)
summary(model2)
M1.anova = anova(model1)
M1.anova
sst1 = sum(M1.anova$'Sum Sq')
pred.r.squared1 = 1 - PRESS(model1)/(sst1)
pred.r.squared1
ols_vif_tol(model1)


M2.anova = anova(model2)
sst2 = sum(M2.anova$'Sum Sq')
pred.r.squared2 = 1 - PRESS(model2)/(sst2)
pred.r.squared2
ols_vif_tol(model2)
R.stdres=rstudent(model1)
ggqqplot(model1$residuals,ggtheme = theme_bw())
#dwtest(model1)
plot(x=model1$fitted.values, y=model1$residuals, xlab='fitted.values',ylab='residuals',pch=16,col='blue')
abline(0,0,col="red",lty=2)


backward.lm=step(full, scope = list(lower=null,upper=full), direction="backward",test="F")


ols_plot_cooksd_chart(model1)
ols_plot_dffits(model1)

inflm.SR = influence.measures(model1)
inflm.SR # all
which(apply(inflm.SR$is.inf, 1, any)) # which
#observations 'are' influential
summary(inflm.SR) # only these

model3=lm(PM10~CO+NO+SO2+Temp+RH, test)
summary(model3)

pred=predict(model3, data = test)
error=test$PM10-pred

MSE=sum(error^2)/10
MSE
