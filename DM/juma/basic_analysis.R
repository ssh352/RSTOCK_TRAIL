
kpi_date = as.Date('2016-06-01')

#新增用户，服务单情况
increase_cus =cusdt[which(cusdt$首次服务日期 >= kpi_date),]
increase_cus_num = nrow(increase_cus)


increase_orders =orderdt[which(orderdt$服务日期 >= kpi_date),]
increase_orders_num = nrow(increase_orders)

suborders = orderdt[which(orderdt$服务日期 >= kpi_date),]

#kpi 趋势
#客户
cus_date = cusdt$首次服务日期
cus_date_m = strftime(cus_date,format = '%Y-%m')
cus_dt_m = aggregate(cus_date_m,by = list(cus_date_m),length)


cus_date_w = strftime(cus_date,format = '%Y-%W')
cus_dt_w = aggregate(cus_date_w,by = list(cus_date_w),length)
#订单
order_date = orderdt$服务日期
order_date = as.Date(order_date)
order_date_m = strftime(order_date,format = '%Y-%m')
order_dt_m = aggregate(order_date_m,by = list(order_date_m),length)

order_date_w = strftime(order_date,format = '%Y-%W')
order_dt_w = aggregate(order_date_w,by = list(order_date_w),length)

#线性回归 预测建模
l = length(cus_dt_m[,2])
fm = lm(y~x,data.frame(x=1:l,y=cus_dt_m[,2]))
pr = floor(predict(fm,data.frame(x=1:(l+3))))

#预测客户总量
pr_cus_num = nrow(cusdt) + sum(pr[(l+1):(l+3)])

#绘图分析
plot(order_dt_m[,2],xaxt = 'n',type='o',col='red',xlab='',ylab = '',xlim = range(1,10))
text(x=1:length(order_dt_m[,2]),y=order_dt_m[,2] + 20,labels=order_dt_m[,2],col = 'red')
axis(1, 1:nrow(cus_dt_m),cus_dt_m[,1])
axis(1,(l+1):(l+3),c('2016-07','2016-08','2016-09'))

lines(cus_dt_m[,2],type="o",pch=22,lty=2,col='green')
text(x=1:length(cus_dt_m[,2]),y=cus_dt_m[,2],labels=cus_dt_m[,2],col='green')
lines(1:(l+3),y = pr,col = 'black' )
text(x=1:(l+3),y=pr,labels=pr,col='black')

title(main="增长趋势", col.main="red", font.main=4)
title(xlab= "日期", col.lab=rgb(0,0.5,0))
title(ylab= "数量", col.lab=rgb(0,0.5,0))
legend(1, max(order_dt_m[,2]), c('订单增长','客户增长','预测增长'),bty='n', cex=0.8, col=c('red','green','black'), pch=c(21,22,22), lty=c(1,2,1));
legend(l, max(order_dt_m[,2]), paste('预测总用户:',pr_cus_num),bty='n');

#留存率趋势,每个月的客户的留存情况

sur_date = as.Date(c('2016-02-29','2016-03-31','2016-04-30','2016-05-31','2016-06-20'))
#总留存
surv_rates = unlist( lapply(sur_date, function(x,ulist,olist){
  cusflag = cus_flag_func(ulist,olist,x)
  rate = survival_rate(cusflag)
  return(rate)
  },cusdt,orderdt) )

plot(1:length(surv_rates),surv_rates,xaxt = 'n',type='o',col='red',xlab='',ylab = '')
text(x=1:length(surv_rates),y=surv_rates,labels=round(surv_rates,3),col = 'red')
axis(1, 1:length(surv_rates),sur_date)


#服务车辆车次的分布
cars_num = data.frame()
cars = unique(suborders$服务车编号)
for(car in cars)
{
  xorders = subset(suborders,服务车编号 == car)
  
  x = union(grep('氟',xorders$服务项目),grep('氟',xorders$备注))
  
  dates = xorders[,'服务日期']
  dates_num = length(unique(dates))
  
  r = data.frame(车牌=car,出车=dates_num,加氟活动=length(x),其他服务=nrow(xorders)-length(x),平均单=nrow(xorders)/dates_num)
  cars_num = rbind(cars_num,r)
}
cars_num
#分布地域

address = orderdt$服务地址
aggregate(address,by=list(address),length)

keywords = c('金府','安靖','八里','八一|八益','白家','百脑汇','北富森','博雅','成绵','川陕','福锦路|聚龙|巨龙',
             '剑龙','金府','万贯','量力','龙泉','龙潭','摩尔','郫县','十陵','双流','新都','金三角')

flagwords = c()
mathed = F
for(a in address)
{
  for(k in keywords)
  {
    i = grep(k,a)
    if(length(i) > 0)
    {
      flagwords = c(flagwords,k)
      mathed = T
      break
    }
  }
  if(!mathed)
  {
    flagwords = c(flagwords,a)
  }
  else
  {
    mathed = F
  }
}
aggregate(flagwords,by=list(flagwords),length)


#活跃度，总体分析
enddate = as.Date('2016-06-20')
startdate = enddate - 60

subcusnos = na.omit(subset(cusdt,as.Date(首次服务日期) > startdate)$序号) 

subcusnos = na.omit(cusdt$序号) 


suborderdt = subset(orderdt,cusno %in% subcusnos)

dt = aggregate(suborderdt[,'cusno'],by=list(suborderdt[,'cusno']),length)
dt_sum = aggregate(dt[,2],by=list(dt[,2]),length)
colnames(dt_sum) = c('使用次数','车辆总数')

xx = subset(dt,dt[,2] == 10)

#活跃度细分
#未满60天
#45天以内，体验客户
cusflag = cus_flag_func(cusdt,orderdt,enddate)

dt_cus_flag = aggregate(cusflag$flag,by = list(cusflag$flag),length)
colnames(dt_cus_flag) = c('客户类别','客户量')
dt_cus_flag$比例 = dt_cus_flag$客户量/nrow(cusflag)

survrate = survival_rate(cusflag)
  
pie(dt_cus_flag[,2],main="客户分布情况",col=rainbow(length(dt_cus_flag[,2])),labels=dt_cus_flag[,1])
pr_cus_surv = floor(survrate * pr_cus_num) 

#活动分析
#备注及服务项目中出现氟
activitidate = as.Date('2016-06-13')
s1 = grep('氟',orderdt$服务项目)
s2 = grep('氟',orderdt$备注)
s = union(s1,s2)

s = orderdt[s,]
actorders = subset(s,s$服务日期 >= activitidate)
actcus = unique(na.omit(actorders$cusno))

preorders = subset(orderdt,orderdt$服务日期 < activitidate)

#老客户激活
oldcus = subset(cusdt,as.Date(cusdt$首次服务日期) < activitidate )$序号
reaccesscus = actcus[actcus %in% oldcus]
reaccesscus_num = length(reaccesscus)
reaccesscus_rate = round(reaccesscus_num / length(oldcus),3)
preoldolders = subset(preorders,cusno %in% reaccesscus)

#流失客户激活
preactdate  = as.Date('2016-06-12')
cus_flag_preact = cus_flag_func(cusdt,orderdt,preactdate)
death_cus = subset(cus_flag_preact,flag %in% c('流失用户','流失体验用户'))
death_cus_num = nrow(death_cus)

death_to_live = reaccesscus[which(reaccesscus %in% death_cus$cusno)]
death_to_live_num = length(death_to_live)

predt = aggregate(as.Date(preoldolders[,c('服务日期')]),by = list(preoldolders$cusno),max)
colnames(predt) = c('客户号','最近访问日期')
predt$距离最近未访问天数 = activitidate - predt$最近访问日期

#death_to_live = subset(predt,距离最近未访问天数 > 60)
#真实拉新
newcus = actcus[!(actcus %in% oldcus)]
newcus_num = length(newcus)
# 绘图
op = par(mfrow=c(1,2))
barplot(c(newcus_num,reaccesscus_num),main="拉新分析",names.arg=c(paste('新客户',newcus_num),paste('回头客',reaccesscus_num)),
        border="blue",col=c('red','yellow'))
legend(0, newcus_num ,paste('回头率:',reaccesscus_rate), cex=0.8);

barplot(matrix(c(death_to_live_num,death_cus_num-death_to_live_num)), col = c("lightblue", "mistyrose") ,legend=c(paste('挽回客户',death_to_live_num),paste('流失客户',death_cus_num)))
title('唤醒分析')
par(op)
#拉新激活
neworders = subset(actorders,cusno %in% newcus)
aggregate(neworders$cusno,by = list(neworders$cusno),length)

oldorders = subset(actorders,cusno %in% oldcus)
aggregate(oldorders$cusno,by = list(oldorders$cusno),length)



#提取流失客户

death_cus_all = subset(cusflag,flag %in% c('流失用户','流失体验用户'))
cuslist = merge(death_cus_all,cusdt[,c('序号','客户姓名','电话','车牌号码')],by.x = 'cusno',by.y = '序号')

cuslist = cuslist[,c('客户姓名','电话','车牌号码','lastdate')]
colnames(cuslist) = c('客户姓名','电话','车牌号码','最近一次使用日期')
#write.csv(cuslist,'d:/流失客户名单.csv',row.names = F)
