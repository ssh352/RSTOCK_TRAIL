#根据stageanalyse的代码整合在函数
rm(list=ls(all=T))
require(quantmod)
require(TTR)
require('dygraphs')
require('lubridate')
require('dplyr')
require(e1071)
require(randomForest)
sourceDir <- function(path, trace = TRUE, ...) {
  for (nm in list.files(path, pattern = "[.][RrSsQq]$")) {
    if(trace) cat(nm,":")
    source(file.path(path, nm), ...)
    if(trace) cat("\n")
  }
}

sourceDir('D:/Rcode/code/RSTOCK_TRAIL/trade/wensitan/help')
sourceDir('D:/Rcode/code/RSTOCK_TRAIL/trade/wensitan/log')
#sourceDir('D:/Rcode/code/RSTOCK_TRAIL/trade/wensitan/trade')
sourceDir('D:/Rcode/code/RSTOCK_TRAIL/trade/wensitan/analysis')

#加入大盘阶段判断信息
shindex = readSHindex()
shindex_week = to.weekly(shindex)
shindex_week$sma30 = SMA(Cl(shindex_week),n=30)
shindex_week = na.omit(shindex_week)
shindex_week$volatile = (Cl(shindex_week)-Op(shindex_week))/Op(shindex_week)

shindex_week$stage = judegeStage(shindex_week$sma30)
shindex_week = na.omit(shindex_week)

#添加周平均成交 周大盘上升股比例交量等信息
shindex_week$meanVolume = apply.weekly(shindex[,'Volume'],mean)
shindex_week$mvSma10 = lag(SMA(shindex_week$meanVolume,10),1)
shindex_week$mvratio = shindex_week$meanVolume  / shindex_week$mvSma10 
shindex_week = na.omit(shindex_week)
#读入所有行业
lookups_hy = readallHy(sman=30)

#读入行业代码
codeTable = readHycode()

#读入所有数据
lookups = readallstock(codeTable,shindex_week,sman=30)
#形成列表
mg = mget(lookups)
mgl=lapply(mg,function(x){x$volatile})
mm = do.call("merge",args=mgl)

#计算上升比
uptorange = function(x)
{
  total = length(which(is.na(x) == F))
  i = length(which(x > 0 ))
  return(i / total)
}
uplist = apply(mm,FUN=uptorange,MARGIN=1)
names(uplist) = ''
uplist = xts(uplist,index(mm))
tempdata = apply.weekly(uplist,mean)
shindex_week = merge(shindex_week,tempdata)
shindex_week = na.omit(shindex_week)
colnames(shindex_week) = c('Open','Hign','Low','Close','Volume','sma30','volatile','stage','meanVolume','mvSma10','mvratio','upratio')

save(list=append(lookups,c('shindex_week','lookups')),file='allStock.Rdata')

#处理每个时间的筛选
#shindex_week = shindex_week['1996/']
xxs = shindex_week['20150925']
#xxs = xxs[xxs$stage!=4]
end = index(xxs)

print(now())

allcodes = names(mg)
ld = lapply(end,function(x){
  print(x)
  l = filterBasicOneDay(as.character(x),mg,shindex_week,lastn=5)#growRatioGreaterThanDegreeWithIndex(as.character(x),mg,ratio=0.07,shindex_week)#
  l=Filter(function(x){!is.null(x)},l)
  if(length(l) > 0)
  {
    l = list(l)
    names(l) = as.character(x)
    return(l)
  }
  return(NULL)
    })

#l = Filter(function(x){ ll = x[[1]]
 #                       ll = Filter(function(x){!is.null(x[[1]])},ll)
  #                      length(ll)!=0},ld[1:2])

l = Filter(function(x){ ll = x[[1]]
                        length(ll)!=0},ld)
names(l)=sapply(l,function(x){return(names(x))})
print(now())

save(l,file='wensitan.Rdata')

sepdays = c()

#测试list里面的每个选项
for(i in 1:length(l))
{
  print(i)
  p = l[[i]]
  pdate = names(p) 
  print(pdate)
  p = p[[1]]
 sdays =  sapply(p,function(x,pdate){
    pname = x[[1]]
    print(pname)
    sep =findtimeGapWhengrowToSomeDegree(pname,pdate,0.05)# afterNdaysProfit(pname,pdate,10)#
    return(sep)
  },pdate)
 print(sdays)
 sepdays = c(sdays,sepdays)
 
}
sepdays =  unlist(sepdays)
sepdays = sepdays[!is.na(sepdays)]
length(sepdays[sepdays<10 & sepdays>0]) / length(sepdays)

seps = list()
# look for good 
for(i in 1:length(l))
{
  print(i)
  p = l[[i]]
  pdate = names(p) 
  
  p = p[[1]]
  sep =  sapply(p,function(x,pdate){
    pname = x[[1]]
    # print(pname)
    sp = findStockWhengrowToSomeDegree(pname,pdate,0.5)
    return(sp)
  },pdate)
  
  if(!is.null(sep)) seps = append(seps,sep)
  
}
#test for one code
code = '600390'
mgone = list(get(code))
names(mgone) = code
ldone = lapply(end,function(x){
  l = filterBasicOneDay(as.character(x),mgone,shindex_week)
  l = list(l)
  names(l) = as.character(x)
  return(l)
})

lone = Filter(function(x){ ll = x[[1]]
                        length(ll)!=0},ldone)
names(lone)=sapply(lone,function(x){return(names(x))})

#exit and portofolio management
#产生回测记录

records = list()
print(now())
for(i in 1:length(l))
{
  p = l[[i]]
  pdate = names(p) 
  print(pdate)
  
  p = p[[1]]
  trades =  lapply(p,function(x,pdate){
    pname = x[[1]]
    #print(pname)
    record =afterNatrExit(pname,pdate,3,1,1)
    return(record)
  },pdate)
  records = append(records,trades)
  # print(trades)
}

records = as.data.frame(do.call('rbind',records))
records = subset(records,!is.na(records[,'code']))
print(now())

profit = as.numeric(records[,'profit'])
sum(profit)
max(profit)
min(profit)
length(profit[profit>0]) / length(profit)

everyyear = year(ymd(records[,'opdate']))

aggregate(x=profit,by=list(everyyear),sum)

sub = subset(records,year(ymd(opdate))==2011 & Open > 10 & Open<30)

sub[,'opdate'] = ymd(sub[,'opdate'] )
sub[,'cldate'] =  ymd(sub[,'cldate'] )
sepweeks=ceiling(as.numeric((ymd(sub[,'cldate']) - ymd(sub[,'opdate']))) / 7)
sub = cbind(sub,sepweeks)

profit = as.numeric(sub[,'profit'])
sub = cbind(sub,profit)
#如果同天有多笔交易，随机挑选一笔
x=aggregate(profit~opdate,data=sub[,c(2,8)],function(x){n=sample(1:length(x),1)
                                                        return(x[n])})
head(x[order(x$opdate),])
sum(x[,2])

#分析记录 绘图
x=get('600423')
plot(Cl(x['201010/201107']))
points(x['201010/201107']$sma30,type='l',col='red')
plot(Cl(shindex_week['201010/201107']))
points(shindex_week['201010/201107']$sma30,type='l',col='red')

#ml learning 机器学习筛选条件框架
dt =unlist(records[,'opdate'])
indexsh = index(shindex_week)
indexinfo = lapply(dt, function(x){
  p = which(indexsh == x)
  if(length(p) == 0)
  {
    print(x)
    p = findInterval(as.Date(x),indexsh)
  }
  else
  {
    p = p - 1
  }
  
  currentp = coredata(shindex_week[p,])
  return(list(stage=currentp[,'stage'],volatile=currentp[,'volatile']))
})

#添加交易周内的上证信息并将交易盈亏进行标示
indexinfo = as.data.frame(do.call('rbind',indexinfo))
stage = unlist(indexinfo$stage)
stage = as.factor(stage)
votile = unlist(indexinfo$volatile)
profit = unlist(records$profit)
profitflags = ifelse(profit>0,'good','bad')
recordsinfo = cbind(records,stage)
recordsinfo = cbind(recordsinfo,votile)
recordsinfo = cbind(recordsinfo,profitflags)
#寻找前一个交易日的信息，避免look ahead
preinfo = apply(records,MARGIN=1,FUN=function(rowdata)
  {
  code = as.character(rowdata['code'])
  pdate =as.Date(unlist(rowdata[2]))
  pdata = get(code)
  pindex = which(index(pdata) == pdate) 
  preindex = pindex-1
  predata = pdata[preindex,]
  preclose = as.numeric(Cl(predata))
  presma30 = as.numeric(predata[,'sma30'])
  prevolatile = as.numeric(predata[,'volatile'])
  preatr = as.numeric(predata[,'atr'])
  premeanvo = as.numeric(predata[,'meanVolume'])
  premvratio = as.numeric(predata[,'mvratio'])
  prers = as.numeric(predata[,'rs'])
  
  
  while(is.na(preclose))
  {
    preindex = preindex-1
    predata = pdata[preindex,]
    preclose = as.numeric(Cl(predata))
    presma30 = as.numeric(predata[,'sma30'])
    prevolatile = as.numeric(predata[,'volatile'])
    preatr = as.numeric(predata[,'atr'])
    premeanvo = as.numeric(predata[,'meanVolume'])
    premvratio = as.numeric(predata[,'mvratio'])
    prers = as.numeric(predata[,'rs'])
  }
  return(list(preclose=preclose,presma30=presma30,prevolatile=prevolatile,preatr=preatr
              ,premeanvo=premeanvo, premvratio=premvratio,prers=prers))  
})
preinfoframe = as.data.frame(do.call('rbind',preinfo))
recordsinfo = cbind(recordsinfo,preinfoframe)
#处理data.frame的列格式
for(i in colnames(recordsinfo))
{
  recordsinfo[,i] = unlist(recordsinfo[,i])
}

#建模区分好坏交易
model <- glm(profitflags ~ Open + stage + votile  + initStop,data = recordsinfo,family = 'binomial',control=list(maxit=100))

#model <- glm(profitflags ~ Open+initStop,data = recordsinfo,family = 'binomial')

year = 1996:2015
testindex = sample(1:20,10)
testyear = 1996:2010
trainyear = c(2011)#year[-testindex]
testset = recordsinfo[which(as.numeric(substr(recordsinfo$opdate,1,4)) %in% testyear),]
trainset = recordsinfo[which(as.numeric(substr(recordsinfo$opdate,1,4)) %in% trainyear),]

model <- randomForest(profitflags ~ stage + votile  + initStop + preclose,data = testset)
#model <- svm(profitflags ~ preclose + stage + votile  + initStop,data = testset,gamma = 0.5)
model <- glm(profitflags ~ preclose + initStop  ,data = testset,family = 'binomial')

profitpredict = predict(model,subset(trainset,select=c(preclose,stage,votile,initStop)),type='response')
#profitpredict = ifelse(profitpredict>0.7,'good','bad')
table(trainset[,'profitflags'],profitpredict)

#truemodel = model <- glm(profitflags ~ preclose + stage + votile  + initStop,data = recordsinfo,family = 'binomial',control=list(maxit=100))
truemodel <- randomForest(profitflags ~ preclose +  stage + votile  + initStop,data = recordsinfo)
profitpredict = predict(truemodel,type='response')
#profitpredict = ifelse(profitpredict>0.7,'good','bad')
table(recordsinfo[,'profitflags'],profitpredict)
trainset = recordsinfo

predicttrade = which(profitpredict == 'good')
predicttrade = trainset[predicttrade,]
profit = as.numeric(predicttrade[,'profit'])
sum(profit)
max(profit)
min(profit)
length(profit[profit>0]) / length(profit)

everyyear = year(ymd(predicttrade[,'opdate']))

aggregate(x=profit,by=list(everyyear),sum)
subset(predicttrade,substr(opdate,1,4)==2008)