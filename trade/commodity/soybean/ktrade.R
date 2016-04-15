rm(list=ls(all=T))
source('D:/Rcode/code/RSTOCK_TRAIL/globaltool/include.R')
source('D:/Rcode/code/RSTOCK_TRAIL/globaltool/readdata.R')
sourceDir('D:/Rcode/code/RSTOCK_TRAIL/trade/eventAnalysis')
pricedata = collectdatafromtaobao()

days = as.character(unique(as.Date(index(pricedata))))

records = data.frame()
for(day in days)
{
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  
  time1 = paste(day,'09:01:00')
  time2 = paste(day,'09:10:00')
  time3 = paste(day,'15:00:00')
  
  open = as.numeric(p[time1]$Open)
  end1 = as.numeric(p[time2]$Close)
  end2 = as.numeric(p[time3]$Close)
  r = data.frame(date=day,open = open,end1 = end1,end2=end2,sign1 = sign(end1 - open),sign2 = sign(end2 - open))
  records = rbind(records,r)
}

years = unique(substring(days,1,7))
anlysisframe = data.frame()
for(y in years)
{
  sub = subset(records,substring(date,1,7) == y)
  sub1 = subset(sub,sign1 == sign2)
  ratio = nrow(sub1) / nrow(sub)
  a = data.frame(year = y , ratio = ratio)
  anlysisframe = rbind(anlysisframe,a)
}

#最高最低点 时间分布统计 暂时只考虑9-15点
maxtime  = c()
mintime = c()
for(day in days)
{
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  p = p[perd]
  maxp = max(p$High)
  maxi = which(p$High == maxp)
  maxi = unique(substring(as.character(index(p[maxi,])),12,13))
  maxtime = c(maxtime,maxi)
  
  minp = min(p$Low)
  mini = which(p$Low == minp)
  mini = unique(substring(as.character(index(p[mini,])),12,13))
  mintime = c(mintime,mini)
}
aggregate(maxtime,by = list(maxtime),length)
aggregate(mintime,by = list(mintime),length)

#回测
records = data.frame()
for(day in days)
{
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  
  time1 = paste(day,'09:01:00')
  time2 = paste(day,'09:10:00')
  time3 = paste(day,'15:00:00')
  
  open = as.numeric(p[time1]$Open)
  end1 = as.numeric(p[time2]$Close)
  end2 = as.numeric(p[time3]$Close)
  type = ''
  if((end1 - open) < 0 )
  {
    type = 'short'
  }
  else if((end1 - open) == 0)
  {
    next
  }
  else
  {
    type = 'long'
  }
  
  i = which(as.character(index(p)) == time2) + 1
  enter = as.numeric(p[i,]$Open)
  if(type =='short')
  {
    stopprice = open + 100
    stopwin = enter - 10
  }
  else
  {
    stopprice = open - 100
    stopwin = enter + 10
    
  }
  isstop = F
  for(idx in i : nrow(p))
  {
    idxcl = as.numeric(p[idx,]$Close)
    if(type == 'short')
    {
      if(idxcl > stopprice)
      {
        isstop = T
        r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = enter - idxcl )
        records = rbind(records,r)
        break
      }
      
      if(idxcl < stopwin)
      {
      #  isstop = T
       # r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = enter - idxcl )
       # records = rbind(records,r)
      #  break
      }
    }
    else
    {
      if(idxcl < stopprice)
      {
        isstop = T
        r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = idxcl - enter )
        records = rbind(records,r)
        break
      }
      
      if(idxcl > stopwin)
      {
       # isstop = T
      #  r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = enter - idxcl )
       # records = rbind(records,r)
      #  break
      }
    }
  }
  if(isstop == F)
  {
    r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = ifelse(type == 'long',(idxcl - enter),( enter - idxcl)) )
    records = rbind(records,r)
  }
}


#回测-早上九点时段决定区间
records = data.frame()
for(day in days)
{
  print(day)
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  p = p[perd]
  
  time1 = paste(day,'09:01:00')
  time2 = paste(day,'10:00:00')
  tp = paste(time1,time2,sep='/')
  
  open = as.numeric(p[time1]$Open)
  upperline = max(p[tp]$High)[1] +3 
  lowerline = min(p[tp]$Low)[1]  - 3
  centerline = floor((upperline + lowerline) / 2)
  if((upperline - lowerline) < 20) next
  
  i = which(as.character(index(p)) == time2) + 1
  type = ''
  ishold = F
  stepped = F
  longcount = 0
  shortcount = 0
 # idx = i
  for(idx in i : (nrow(p)-1))
  {
    idxcl = as.numeric(p[idx,]$Close)
    if(idxcl > upperline && ishold == F && longcount < 1)
    {
      ishold = T
      type = 'long'
      enter = as.numeric(p[idx+1,]$Open)
      entertime = index(p[idx+1,])
      stopprice = centerline
      stopwinprice = enter
      longcount = longcount + 1
      next
    }
    if(idxcl < lowerline  && ishold == F && shortcount < 1)
    {
      ishold = T
      type = 'short'
      enter = as.numeric(p[idx+1,]$Open)
      entertime = index(p[idx+1,])
      stopprice = centerline
      stopwinprice = enter
      shortcount = shortcount + 1
      next
    }
    
    if(ishold == T)
    {
      if(type == 'long')
      {
        #止损
        if(idxcl < stopprice)
        {
          out = as.numeric(p[idx+1,]$Open)
          outtime = index(p[idx+1,])
          r = data.frame(entertime = entertime,enter = enter,outtime = outtime,out = out,stepped=stepped,isstop = T,type = type,profit =out-enter,up=upperline-open,low=open-lowerline)
          records = rbind(records,r)
          ishold = F
          
        }
        #移动止损
        if(idxcl > stopwinprice + 10)
        {
          stepped = T
          stopprice = stopwinprice + 5
          stopwinprice = idxcl
          
        }
      }
      if(type == 'short')
      {
        #止损
        if(idxcl > stopprice)
        {
          out = as.numeric(p[idx+1,]$Open)
          outtime = index(p[idx+1,])
          r = data.frame(entertime = entertime,enter = enter,outtime = outtime,out = out,stepped=stepped,isstop = T,type = type,profit =enter-out,up=upperline-open,low=open-lowerline)
          records = rbind(records,r)
          ishold = F
          
        }
        if(idxcl < stopwinprice - 10)
        {
          stepped = T
          stopprice = stopwinprice  - 5
          stopwinprice = idxcl
          
          
        }
      }
    }
  }
  if(ishold == T)
  {
    out = as.numeric(p[idx+1,]$Open)
    outtime = index(p[idx+1,])
    r = data.frame(entertime = entertime,enter = enter,outtime = outtime,out = out,stepped=stepped,isstop = F,type = type,profit =ifelse(type == 'long',(out-enter),(enter-out)),up=upperline-open,low=open-lowerline)
    records = rbind(records,r)
  }
  
  
}

year = substring(records$entertime,1,4)
months = substring(records$entertime,1,6)
profits = records$profit
aggregate(x=profits,by=list(year),sum)
length(profits[profits>0]) / length(profits)
sum(profits)
length(profits)
sum(profits[profits>0])
sum(profits[profits<0])


subrecords = subset(records,substring(records$entertime,1,4) == '2016')
subprofits = subrecords$profit
subyear = substring(subrecords$entertime,1,7)
aggregate(x=subprofits,by=list(subyear),sum)

sum(subprofits)
length(subprofits[subprofits>0]) / length(subprofits)
sum(subprofits[subprofits>0])
sum(subprofits[subprofits<0])