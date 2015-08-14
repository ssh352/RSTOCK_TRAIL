#根据stageanalyse的代码整合在函数
rm(list=ls(all=T))
require(quantmod)
require(TTR)
require('dygraphs')
require('lubridate')
require('dplyr')

sourceDir <- function(path, trace = TRUE, ...) {
  for (nm in list.files(path, pattern = "[.][RrSsQq]$")) {
    if(trace) cat(nm,":")
    source(file.path(path, nm), ...)
    if(trace) cat("\n")
  }
}

sourceDir('D:/Rcode/code/RSTOCK_TRAIL/trade/wensitan/help')

#加入大盘阶段判断信息
shindex = readSHindex()
shindex_week = to.weekly(shindex)
shindex_week$sma30 = SMA(Cl(shindex_week),n=30)
shindex_week = na.omit(shindex_week)

shindex_week$stage = judegeStage(shindex_week$sma30)
shindex_week = na.omit(shindex_week)

#添加周平均成交 周大盘上升股比例交量等信息
shindex_week$meanVolume = apply.weekly(shindex[,'Volume'],mean)
shindex_week$mvSma10 = lag(SMA(shindex_week$meanVolume,10),1)
shindex_week$mvratio = shindex_week$meanVolume  / shindex_week$mvSma10 
shindex_week = na.omit(shindex_week)
#读入所有行业
lookups_hy = readallHy()

#读入行业代码
codeTable = readHycode()

#读入所有数据
lookups = readallstock(codeTable,shindex_week)
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
colnames(shindex_week) = c('Open','Hign','Low','Close','Volume','sma30','stage','meanVolume','mvSma10','mvratio','upratio')



#处理每个时间的筛选
#shindex_week = shindex_week['1996/']
xxs = shindex_week['1996/']
xxs = xxs[xxs$stage!=4]
end = index(xxs)

print(now())

allcodes = names(mg)
ld = lapply(end,function(x){
  l = filterBasicOneDay(as.character(x),mg,shindex_week)
  l = list(l)
  names(l) = as.character(x)
  return(l)
    })

l = Filter(function(x){ ll = x[[1]]
                        length(ll)!=0},ld)
names(l)=sapply(l,function(x){return(names(x))})
print(now())

save(l,file='result01.Rdata')

sepdays = c()

#测试list里面的每个选项
for(i in 1:length(l))
{
  print(i)
  p = l[[i]]
  pdate = names(p) 
  
  p = p[[1]]
 sdays =  sapply(p,function(x,pdate){
    pname = x[[1]]
   # print(pname)
    sep = findtimeGapWhengrowToSomeDegree(pname,pdate,0.5)
    return(sep)
  },pdate)
 
 sepdays = c(sdays,sepdays)
 
}
sepdays =  unlist(sepdays)
sepdays = sepdays[!is.na(sepdays)]
length(sepdays[sepdays<20]) / length(sepdays)

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

#exit and portofolio management
