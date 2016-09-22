rm(list = ls(all=T))
path = 'd:/lottery.csv'
data = read.csv(path)
data$时间 = paste(data$时间,':00',sep='')
data$时间 = as.POSIXct(data$时间)

x1 = seq(1,nrow(data)-1,by = 2)
x2 = seq(0,nrow(data),by = 2)

data_pre = data[x1,]
data_after = data[x2,]
game_data = merge(data_pre,data_after,by = c('时间','序号','比分'))
colnames(game_data) = c('时间','序号','比分','前胜','前平','前负','前类型','后胜','后平','后负','后类型')
game_data$day = substr(game_data$时间,1,10)

game_sub_data = subset(game_data, 后胜 >=1.31 & 后胜 <= 1.6 )

times = unique(game_sub_data$时间)

pre_time = times[1]
win_flag = F
win_count = 0
start_time =  times[1]

gaps = c()
continues = c()
result = data.frame()
game_counts = 0
for(i in 2:length(times))
{
  #print(i)
  time = times[i]
  games = subset(game_sub_data,时间==time)
  games = games[order(games$时间,decreasing = F),]
  game = games[1,]
  
  gap = as.numeric(difftime(time ,pre_time,units = 'mins'))
  if(gap < 120)
  {
    next
  }
  else
  {
    game_counts = game_counts + 1
    score = as.character(game$比分)
    score = strsplit(score,':')
    pre_score = as.numeric(score[[1]][1])
    aft_score = as.numeric(score[[1]][2])
    #主场胜
    if((pre_score - aft_score) > 0)
    {
      if(win_flag)
      {
        win_count = win_count + 1
      }
      else
      {
        win_flag = T
        start_time = time
        win_count = win_count + 1
      }
    }
    else
    {
       if(win_flag )
       {
          gap_mins = as.numeric(difftime(time ,start_time,units = 'mins'))
          continues = c(continues,win_count)
          gaps = c(gaps,gap_mins)
        #  print(start_time)
          r = data.frame(count = win_count,start = start_time,end = time )
          result = rbind(result,r)
       }
      
      win_flag = F
      win_count = 0
    }
  }
  pre_time = time
}

count_dt = aggregate(continues,by=list(continues),length)

get_extrem_gap = function(i,result,func=max)
{
  r_sub = subset(result,count >= i)
  if(nrow(r_sub) < 2) return(0)
  r_sub = r_sub[order(r_sub$start,decreasing = F),]
  gap_game = c()
  pre = r_sub[1,]
  for(i in 2:nrow(r_sub))
  {
    r = r_sub[i,]
    gap_i = as.numeric(difftime(r$start ,pre$end,units = 'mins'))
    pre = r
    gap_game = c(gap_game,gap_i)
  }
  return(func(gap_game))
}

counts = unique(result$count)
counts =counts[order(counts,decreasing = F)]
maxes = unlist(lapply(counts, get_extrem_gap,result)) / (60 * 24)
mins = unlist(lapply(counts, get_extrem_gap,result,min))
data.frame(counts,maxes,mins)