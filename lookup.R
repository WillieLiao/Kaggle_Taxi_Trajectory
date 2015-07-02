library(data.table)
source('util.R')

### MAKE WIDE AND PRECALCULATE FOR EASIER LOOKUP
poly[, n:=1:.N, id]
poly <- merge(poly, poly[, list(id, n=n-1, lon, lat)], by=c('id', 'n'), all.x=T, suffix=c('', '2'))
poly[, max_n:=.N-1L, id]
poly[is.na(lon2), c('lon2', 'lat2'):=list(lon, lat)]
train <- merge(train, poly[n==1, list(id, lon, lat)], by='id', all.x=T)
train <- merge(train, poly[n==max_n | max_n==0, list(id, lon1=lon, lat1=lat, lon2, lat2)], by='id', all.x=T)
train[id>0, bear:=get_bear(lon, lat, lon2, lat2)]
train[id>0, bear_cut:=get_bear(lon1, lat1, lon2, lat2)]
setkey(poly, id)
setkey(train, id)

for (d in dates){
  p2 <- poly[train[dt==d & id<0, list(id)]]  
  
  for (t in unique(train[id>0 & dt==d, trip])){    
    ### only look at trips that have lasted at least 90% of test trip
    train_t <- train[trip==t]
    temp <- train[dt==d & readings>=train_t$readings*.9-1 & id<0, !c('dt', 'bear_cut', paste(c('lon', 'lat', 'readings'), 'sub', sep='_')), with=F]
    
    ### only look at locations of trips within 20% of the cutoff time
    p <- p2[temp[, list(id)]][n>=train_t$readings*.8-2 & n<=train_t$readings*1.2+2 & n!=max_n+1L][, list(id, lon, lat, lon2, lat2)]
    temp <- merge(temp, p, all.x=T, by='id', suffix=c('', '_cut'), allow.cartesian=T)
    temp[, dist:=get_dist(lon, lat, train_t$lon, train_t$lat)]
    temp[, dist2:=get_dist(lon2_cut, lat2_cut, train_t$lon2, train_t$lat2)]
    
    ### from above points, get the closest one as the end point for each trajectory
    temp[, dist_both:=(dist+dist2)]
    temp[, min_dist:=min(dist_both), id]    
    temp <- unique(temp[min_dist==dist_both])
    
    ### calc latest bearing only if enough points to establish it
    if (train_t$readings>15){
      temp[, bear:=get_bear(lon, lat, lon2_cut, lat2_cut)]      
      temp[, angle:=abs(bear-train_t$bear)]
      temp[angle>180, angle:=angle-180]
      temp[, bear_cut:=get_bear(lon_cut, lat_cut, lon2_cut, lat2_cut)]      
      temp[, angle2:=abs(bear_cut-train_t$bear_cut)]
      temp[angle2>180, angle2:=angle2-180]
      
      # if stationary at cut, then substitute overall bearing, and vice versa
      temp[lon_cut==lon2_cut & lat_cut==lat2_cut, angle2:=angle]  
      temp[lon==lon2 & lat==lat2, angle:=angle2]        
    } else {
      temp[, angle:=5]
      temp[, angle2:=5]
    }    
    temp[, w:=1/(abs(dist)+abs(dist2)+abs(angle)/5+abs(angle2)/5)]			
    
    ### start with a small good subset and expand if not enough similar trajectories
    test <- temp[dist<.5 & dist2<1 & angle<15 & angle2<30]
    if (test[,.N]>2){
      test <- test[order(w, decreasing=T)][1:50][!is.na(w)]
      test <- test[, list(lon=weighted.mean(lon2, w=w), lat=weighted.mean(lat2, w=w), readings=exp(weighted.mean(log(readings), w=w)))]
      train[id==train_t$id, paste(c('lon', 'lat', 'readings'), 'sub', sep='_'):=test]  
    } else {
      test <- temp[dist<.7 & dist2<2 & angle<30 & angle<45]  
      if (test[,.N]>2){  
        test <- test[order(w, decreasing=T)][1:50][!is.na(w)]
        test <- test[, list(lon=weighted.mean(lon2, w=w), lat=weighted.mean(lat2, w=w), readings=exp(weighted.mean(log(readings), w=w)))]
        train[id==train_t$id, paste(c('lon', 'lat', 'readings'), 'sub', sep='_'):=test]  
      } else {
        test <- temp[order(w, decreasing=T)][1:50][!is.na(w)]
        test <- test[, list(lon=weighted.mean(lon2, w=w), lat=weighted.mean(lat2, w=w), readings=exp(weighted.mean(log(readings), w=w)))]
        train[id==train_t$id, paste(c('lon', 'lat', 'readings'), 'sub', sep='_'):=test]  
      }        
    }  
    rm(temp, train_t, test, p); gc()
  }      
  rm(p2); gc()  
}

write.csv(train[id>0, list(TRIP_ID=trip, LATITUDE=lat_sub, LONGITUDE=lon_sub)], 'output/final_loc.csv', row.names=F)
write.csv(train[id>0, list(TRIP_ID=trip, TRAVEL_TIME=readings_sub*15)], 'output/final_time.csv', row.names=F)  
