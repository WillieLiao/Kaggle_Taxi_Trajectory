library(rjson)
library(data.table)

### READ
train <- fread('input/train.csv', select=c('TRIP_ID', 'TIMESTAMP', 'MISSING_DATA', 'POLYLINE'), stringsAsFactors=F)
test <- fread('input/test.csv', select=c('TRIP_ID', 'TIMESTAMP', 'MISSING_DATA', 'POLYLINE'), stringsAsFactors=F)
train[, id:=-seq(.N, 1, -1)]
test[, id:=1:.N]
train <- rbind(train, test)
rm(test)
setnames(train, c('trip', 'start_time', 'incomplete', 'polyline', 'id'))

### REMOVE MISSING DATA
train <- train[incomplete!='True' & polyline!='[]']

### CONVERT POLYLINE TO LONG TABLE(id, lon, lat)
setkey(train, id)
poly <- train[, transpose(unlist(fromJSON(polyline))), by=id]
setnames(poly, c('id', 'lon', 'lat'))

train[, c('incomplete', 'polyline'):=NULL]
train <- merge(train, poly[, list(readings=.N), id], by='id', all.x=T)

### CONVERT TIMESTAMP
train[, start_time:=as.POSIXct(as.integer(start_time), origin="1970-01-01", tz='GMT')]
train[, end_time:=start_time+15*readings]
train[, c('dt', 't1', 't2'):=list(as.Date(start_time), as.ITime(start_time), as.ITime(end_time))]
train[, day:=wday(dt)]

### SUBSET USING TEST DATE CATEGORIES
### LABEL FROM LARGER TO SMALLER SIZES EVEN THOUGH THERE IS NO OVERLAP IN TIMES 
### BUT IF THERE WERE, WE WANT THE HOLIDAYS TO CONTRIBUTE TO HOLIDAYS, NOT REGULAR COMMUTE
dates <- as.Date(c('2014-09-30', '2014-10-06', '2014-11-01', '2014-08-14', '2014-12-21'))

# Weekday AM commute.
s <- as.ITime('07:30')
e <- as.ITime('09:30')
train[(id<0 & day>=2 & day<=6 & t1<e & t2>s), dt:=dates[1]]

# Weekday PM commute.
s <- as.ITime('16:45')
e <- as.ITime('18:45')
train[id<0 & day>=2 & day<=6 & t1<e & t2>s, dt:=dates[2]]

# Saturday last call.  Assume holiday does not matter.
s <- as.ITime('02:30')
e <- as.ITime('05:00')
train[id<0 & day>=7 & t1<e & t2>s, dt:=dates[3]]

# Weeknight before public holiday.
d <- as.Date(c('2013-08-14', '2013-12-24', '2014-04-17', '2014-04-24', '2014-04-30', '2014-06-09'))
s <- as.ITime('16:00')
e <- as.ITime('20:00')
train[dt %in% d & t1<e & t2>s, dt:=dates[4]]

# Sunday afternoon before public holiday.
d <- as.Date(c('2013-08-11', '2013-12-08', '2013-12-22', '2013-12-29',  '2014-04-13', '2014-04-27', '2014-06-08'))
s <- as.ITime('13:30')
e <- as.ITime('16:45')
train[dt %in% d & t1<e & t2>s, dt:=dates[5]]

train <- train[dt %in% dates, list(id, trip, dt, readings)]

### REMOVE OUTLIERS
train <- train[(readings<900 & readings>8) | id>0]
setkey(train, id)
setkey(poly, id)
poly <- poly[train[, list(id)]]
rm(d, e, s)
