options(stringsAsFactors = F, scipen=9, digits=8)

### Get Haversine distance
get_dist <- function(lon1, lat1, lon2, lat2) {  
  lon_diff <- abs(lon1-lon2)*pi/180
  lat_diff <- abs(lat1-lat2)*pi/180
  a <- sin(lat_diff/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(lon_diff/2)^2  
  d <- 2*6371*atan2(sqrt(a), sqrt(1-a))
  return(d)
}

get_bear <- function(lon1, lat1, lon2, lat2) {  
  lon_diff <- (lon1-lon2)*pi/180
  b <- atan2(sin(lon_diff)*cos(lat2*pi/180), cos(lat1*pi/180)*sin(lat2*pi/180) - sin(lat1*pi/180)*cos(lat2*pi/180)*cos(lon_diff))
  return(b/pi*180)
}
