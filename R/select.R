# do not @exportS3Method - select is not an S3 method
#select <- function(x=NULL,...) UseMethod("select")

#' Select from meta data base
#'
#' Function that searches the meta data base for the requested station data
#' Search priority: ID, name, coordinates, altitude, country,...
#' Can return several matches
#'
#' @param loc A string of characters as the name of the location
#' (weather/climate station) or an object of class "stationmeta".
#' @param param Parameter or element type or variable identifier. There are
#' several core parameters or elements as well as a number of additional
#' parameters. The parameters or elements are: precip = Precipitation (mm) tas,
#' tavg = 2m-surface temperature (in degrees Celcius) tmax, tasmax = Maximum
#' temperature (in degrees Celcius) tmin, tasmin = Minimum temperature (in
#' degrees Celcius)
#' @param src Source: limit the downscaling to a specific data set ("NARP",
#' "NACD", "NORDKLIMA", "GHCNM", "METNOM", "ECAD", "GHCND" and "METNOD")
#' @param stid A string of characters as an identifier of the weather/climate
#' station.
#' @param lon Numeric value of longitude (in decimal degrees East) for the
#' reference point (e.g. weather station) as a single value or a vector
#' containing the range of longitude values in the form of c(lon.min,lon.max)
#' @param lat Numeric value of latitude for the reference point (in decimal
#' degrees North) or a vector containing the range of latitude values in the
#' form of c(lat.min,lat.max)
#' @param alt Numeric value of altitude (in meters a.s.l.) used for selection.
#' Positive value, select all stations above this altitude; for negative
#' values, select all stations below this latitude.
#' @param cntr A string or a vector of strings of the full name of the country:
#' Select the stations from a specified country or a set of countries.
#' @param it A single integer or a vector of integers or Dates. An integer in
#' the range of [1:12] for months, an integer of 4 digits for years (e.g.
#' 2014), or a vector of Dates in the form "2014-01-01").
#' @param nmin Select only stations with at least nmin number of years, months
#' or days depending on the class of object x (e.g. 30 years).
#' @param verbose Logical value defaulting to FALSE. If FALSE, do not display
#' comments (silent mode). If TRUE, displays extra information on progress.
#' @return A \code{data.frame} holding meta data about available station data.
#'
#' @export select.station
select.station <- function (x=NULL, ..., loc=NULL, param=NULL,  ele=NULL, stid=NULL, 
                            lon=NULL, lat=NULL, alt=NULL, cntr=NULL, src=NULL, it=NULL, 
                            nmin=NULL, user='external', update.meta=FALSE, verbose=FALSE) {
  if (verbose) print(match.call())

  ## Use provided metadata in x, or fetch fresh metadata as defined by src
  if (is.null(x)) {
    if (verbose) {
      print('select.station: Fetching metadata from file data/station.meta.r. (x == NULL)')
    }
    ## Load station.meta, either from the esd package itself or, in lieu of that, from the local data folder
    data("station.meta",envir=environment())
    station.meta <- as.data.frame(station.meta)

    if(is.null(src)) {
      if (verbose) print('select.station: Will fetch from frost and thredds. (src == NULL)')
      frost <- TRUE
      thredds <- TRUE
    } else {
      ## KMP 2020-02-17: Redirect monthly metno to Frost and daily to Thredds
      if(user!='metno') src <- sapply(src, function(x) {
        switch(toupper(x), "METNOM"="METNOM.FROST", "METNOD"="METNOD.FROST", x)})
      frost <- any(grepl("FROST",toupper(src)))
      thredds <- any(grepl("THREDDS",toupper(src)))
    }
    ## KMP 2020-02-18: Fetch Frost metadata if it isn't already in station.meta
    if(frost & (update.meta | !any(grepl("FROST",station.meta$source))) ) {
      if (verbose) print("select.station: Fetching frost metadata (month and diurnal).")
      station.meta <- station.meta[!grepl("FROST",station.meta$source),]
      meta <- metno.frost.meta.month(save2file=FALSE, verbose=verbose)
      station.meta <- merge(station.meta, meta, all=TRUE)
      meta <- metno.frost.meta.day(save2file=FALSE, verbose=verbose)
      station.meta <- merge(station.meta, meta, all=TRUE)
      if("METNO.FROST.MINUTE" %in% src) {
        if (verbose) print("select.station: Fetching frost metadata (minute).")
        meta <- metno.frost.meta.minute(save2file=FALSE, verbose=verbose)
        station.meta <- merge(station.meta, meta, all=TRUE)
      }
      if (verbose) print("Fetched fresh frost metadata. What is the status now?")
    }
    ## KMP 2020-02-18: Fetch Thredds metadata if it isn't already in station.meta
    if(thredds & !any(grepl("THREDDS",station.meta$source)) ) {
      if (verbose) print("select.station: Fetching thredds metadata.")
      if(is.null(param)) {
        param.thredds <- c('t2m','tmax','tmin','precip','slp','sd','fx','fg','dd')
      } else {
        param.thredds <- param
      }
      names.meta <- colnames(station.meta)
      names.meta <- sapply(names.meta, function(x) switch(x, "station_id"="station.id", 
                                                          "start"="first.year",
                                                          "end"="last.year", x))
      for(p in param.thredds) {
        if(verbose) print(paste("select.station: meta.thredds for variable",p))
        meta <- meta.thredds(param=p, verbose=verbose)
        meta <- meta[, names.meta[names.meta %in% names(meta)]]
        names(meta) <- sapply(names(meta), function(x) switch(x, "station.id"="station_id", 
                                                             "first.year"="start",
                                                             "last.year"="end", x))
        meta$source <- "METNOD.THREDDS"
        meta$variable <- p
        meta$element <- esd2ele(p)
        station.meta <- merge(station.meta, meta, all=TRUE)
      }
    }
    station.meta$end[is.na(station.meta$end)] <- strftime(Sys.time(), format='%Y')
    #station.meta <- as.data.frame(station.meta,stringsAsFactors=FALSE)
  } else if (inherits(x,"station")) {
     if (verbose) print("select.station: Using metadata passed through input variable x")
     station_id <- attr(x, "station_id")
     location <- attr(x,"location")
     country <- attr(x,"country")
     longitude <- attr(x,"longitude")
     latitude <- attr(x,"latitude")
     altitude <- attr(x,"altitude")
     element <- apply(as.matrix(attr(x,"variable")),1,esd2ele)
     start <- rep(year(x)[1],length(station_id))
     end <- rep(year(x)[length(index(x))],length(station_id))
     source <- attr(x,"source")
     quality <- attr(x,"quality")

     station.meta <- data.frame(station_id = station_id,location = location, country = country,
                                longitude = longitude, latitude = latitude, altitude = altitude,
                                element = element, start = start, end = end,
                                source = source, quality= quality)

     # update ele using element
     ## ele <- element
     ## param <- esd2ele(ele)
  } else if (inherits(x,"data.frame")) station.meta <- x else {
    stop("select.station: x must be an object of class 'station' or a station.meta object (data.frame)") 
  }
  
  ## KMP 2021-05-19: 'src' is an input argument (NULL by default) and if you redefine it here 
  ## the user will not be able to select based on source! If 'src' is missing altogether 
  ## we need to figure out why that happens.
  ## REB 2021-05-11: The variable 'src' seeems to be missing
  #src <- station.meta$source

  if (verbose) {
    print(paste("select.station: station.meta dim:", dim(station.meta)[0], dim(station.meta)[1]))
    print(paste("select.station: station.meta sources:", table(src)))
  }
  if (!is.null(param)) {
    ele <- apply(as.matrix(param),1,esd2ele)
    if (is.null(ele)) {
      print("select.station: No variable found for your selection or the param identifier has not been set correctly.")
      print("select.station: Please refresh your selection based on the list below")
      print(as.matrix(ele2param(src=src))[,c(2,5,6)])
      return(NULL)
    }
  }  

  ## (DEBUG) Save into a file data/station.meta.rda
  #save(file=file.path("data","station.meta.rda"),station.meta)
  
  ## get the length of the data base
  #n <- length(station.meta$station_id)
  if (!is.null(stid) & dim(station.meta)[1]!=0) {
    if(verbose) print("select.station: Search by station identifier")
    if (is.numeric(stid)) {
      id <- is.element(station.meta$station_id,stid)
      station.meta <- station.meta[id,]
    } else if (is.character(stid)) {
      id <- is.element(station.meta$station_id,stid) # grep(stid,station.meta$station_id)
      station.meta <- station.meta[id,]
    }
  }
  if(dim(station.meta)[1]!=0) {
    if (length(lon)==1 & length(lat)==1) {
      if(verbose) print("select.station: Search by the closest station to longitude and latitude values")
      d <- distAB(lon, lat, station.meta$longitude, station.meta$latitude)
      id <- d==min(d,na.rm=TRUE)
      ##id[is.na(id)] <- FALSE # Ak some of the lon values are NA's
      station.meta <- station.meta[id,]
    } else {
      if (!is.null(lon)) {
        if(verbose) print("select.station: Search by longitude values or range of values")
        lon.rng <- range(lon,na.rm=TRUE)
        id <- (station.meta$longitude >= lon.rng[1]) & 
              (station.meta$longitude <= lon.rng[2]) &
              !is.na(station.meta$longitude)
        station.meta <- station.meta[id,]  
      }
      if (!is.null(lat)) {
        if(verbose) print("select.station: Search by latitude values or range of values")
        lat.rng <- range(lat) 
        id <- (station.meta$latitude >= lat.rng[1]) & 
              (station.meta$latitude <= lat.rng[2]) & 
              !is.na(station.meta$latitude)
        station.meta <- station.meta[id,]
      }
    }
  }
  ## Search by altitude values or range of values
  if (!is.null(alt) & dim(station.meta)[1]!=0) {
    if(verbose) print("select.station: Search by altitude values or range of values")
    if (length(alt) == 1) {
      if (alt > 0) alt.rng <- c(alt,10000)
      else alt.rng <- c(0,abs(alt))
    }  else if (length(alt) == 2) {
      alt.rng <- alt      
    }
    id <- (station.meta$altitude >= alt.rng[1]) & 
          (station.meta$altitude <= alt.rng[2]) & 
          !is.na(station.meta$altitude)
    station.meta <- station.meta[id,] 
  }
  ## Search by country name
  if (!is.null(cntr) & dim(station.meta)[1]!=0) {
    if(verbose) print("select.station: Search by country")
    id <- is.element(tolower(station.meta$country),tolower(cntr))
    station.meta <- station.meta[id,]
  }
  ##
  ## Search by data source
  if (!is.null(src) & dim(station.meta)[1]!=0) {
    if(verbose) print("select.station: Search by data source")
    ## Redirect external users to Frost and Thredds for metno data
    if(user!='metno') src <- sapply(src, function(x) {
      switch(toupper(x), "METNOM"="METNOM.FROST", "METNOD"="METNOD.THREDDS", x)})
    id <- is.element(tolower(station.meta$source),tolower(src))
    station.meta <- station.meta[id,]
  } else if(any(grepl("METNO",toupper(station.meta$source))) & user!='metno') {
    ## Redirect external users to Frost and Thredds for metno data
    id <- !is.element(toupper(station.meta$source), c("METNOM","METNOD"))
    station.meta <- station.meta[id,]
  }
  
  if (!is.null(loc) & dim(station.meta)[1]!=0) {
    if(verbose) print("select.station: Search by location")
    ## id <- is.element(tolower(station.meta$location),tolower(loc))
    pattern <- paste(loc,collapse='|')
    id <- grepl(pattern=pattern,station.meta$location,ignore.case=TRUE,...)
    station.meta <- station.meta[id,]
  }

  ## Search by esd element
  if (!is.null(ele) & dim(station.meta)[1]!=0) {
    if(verbose) print("select.station: Search by element")
    id <- is.element(station.meta$element,ele)
    station.meta <- station.meta[id,]
  }
  
  ## Search by minimum number of observations
  if (!is.null(nmin) & dim(station.meta)[1]!=0) { 
    if(verbose) print("select.station: Search by minimum number of observations")
    ny <- as.numeric(station.meta$end) - as.numeric(station.meta$start) + 1
    id <- (ny >= nmin)
    station.meta <- station.meta[id,]
  }
  
  if (verbose) str(station.meta)
  
  
  if (!is.null(it) & dim(station.meta)[1]!=0) {  
    if(verbose) print("select.station: Search by starting and ending years")
    it[it =="now"] <- as.character(as.Date(Sys.time()),format='%Y-%m-%d')
    if(is.dates(it)) it <- as.numeric(strftime(it, format="%Y"))
    it.rng <- range(it)
    if (verbose) print(it)
    ## Keep only stations with data covering the whole selected period:
    #id <- (as.numeric(station.meta$start) <= it.rng[1]) & (as.numeric(station.meta$end) >= it.rng[2])
    start.rng <- as.numeric( sapply(as.numeric(station.meta$start), function(x) max(it.rng[1], x)) )
    end.rng <- as.numeric( sapply(as.numeric(station.meta$end), function(x) min(it.rng[2], x)) )
    n.rng <- as.numeric( sapply(end.rng-start.rng+1, function(x) max(0,x)) )
    
    if (verbose) {print('Number of years of data'); print(summary(n.rng))}
    if(!is.null(nmin)) {
      ## Keep only stations with nmin years of data in the selected period:
      id <- n.rng>=nmin
    } else {
      ## Keep all stations with any data within selected period:
      id <- n.rng>0
    }
    if (verbose) print(paste(sum(id),'stations with more than',nmin,'years of data'))
    if (!any(id)) {
      print(paste('select.station: No records that cover the period ',it.rng[1],'-',it.rng[2],'. Earliest observation from ',
                  min(as.numeric(station.meta$start)),' and latest observation from ',
                  max(as.numeric(station.meta$end)),sep=''))
      return(NULL)
    }
    station.meta <- station.meta[id,]
    ## Why replace the meta data start and end?
    #station.meta$start <- rep(it.rng[1],length(station.meta$loc))
    #station.meta$end <- rep(it.rng[2],length(station.meta$loc))
  }
  # ## Search by esd element - already done!?!
  # if (!is.null(ele) & dim(station.meta)[1]!=0) {
  #   if(verbose) print("select.station: Search by element")
  #   id <- is.element(station.meta$element,ele)
  #   station.meta <- station.meta[id,]
  # }
  ## Outputs
  
  if (dim(station.meta)[1]!=0) {
    station.meta$station_id <- as.character(station.meta$station_id)
    station.meta$location <- as.character(station.meta$location)
    station.meta$country <- as.character(station.meta$country)
    station.meta$source <- as.character(station.meta$source)
    class(station.meta) <- c("stationmeta","data.frame")
    if (verbose) {str(station.meta); print('Returning from select.station')}
    return(station.meta)
  } else {
    print("select.station: No available stations found for your selection")
    return(NULL)
  }
}

# There were two versions of this function. Which one is correct?
select.station.v2 <- function(stid=NULL, param=NULL, lon=NULL, lat=NULL, alt=NULL, cntr=NULL, ...,
   src=NULL, file="station.meta.rda", path="esd/data", silent=FALSE, verbose=FALSE) {
  if(verbose) print("select.station.v2")
  if(!is.null(path)) file <- file.path(path,file)
  if(!file.exists(file)) {
    print(paste("metadata file",file,"not found"))
    return(NULL)
  } else {
    load(file)
    n <- length(station.meta$stid)
    if (!is.null(param)) {
      ele.c <- switch(tolower(param), t2m="101", tg="101", 
                      rr="601", slp="401", cloud="801", t2="101", 
                      precip="601", `101`="101", `401`="401", `601`="601",`801`="801")
      station.meta <- subset(station.meta,element==ele.c)
    }
    if (!is.null(stid)) {
      if (is.numeric(stid)) {
         id <- stid
         station.meta <- subset(station.meta,stid==id)
      } else if (is.character(stid)) {
        id <- grep(tolower(stid),tolower(station.meta$location))
        station.meta <- station.meta[id,]
      }
    }
    if (!is.null(lon) & !is.null(lat)) {
      if ((length(lon) == 1) & (length(lat) == 1)) {
        d <- distAB(lon, lat, station.meta$lon, station.meta$lat)
        id <- d==min(d,na.rm=TRUE) ; id[is.na(id)] <- FALSE # Ak some of the lon values are NA's
        station.meta <- subset(station.meta,id)
      } else if ((length(lon) == 2) & (length(lat) == 2)) {
        lon.rng <- lon ; lat.rng <- lat 
        station.meta <- subset(station.meta,((lon >= lon.rng[1]) & (lon <= lon.rng[2])) &
	                                    (lat >= lat.rng[1]) & (lat <= lat.rng[2]))           
      } else return(NULL)
    }
    if (!is.null(alt)) {
      if (length(alt) == 1) {
         alt.rng <- c(alt-0.1*alt,alt+.1*alt) # set the altitude range to +/-10% of alt
      } else if (length(alt) == 2) {
         alt.rng <- alt      
      }
      station.meta <- subset(station.meta,(alt >= alt.rng[1]) & (alt <= alt.rng[2]))   
    }
    if (!is.null(cntr)) {
      id <- is.element(tolower(station.meta$country),tolower(cntr))
      station.meta <- subset(station.meta,id)   
    }
    if (!is.null(param)) {
      id <- is.element(station.meta$element,ele.c)
      station.meta <- subset(station.meta,id)   
    }
    if (!is.null(src)) {
      id <- is.element(station.meta$src, src) 
      station.meta <- subset(station.meta,id)
    }
    if (dim(station.meta)[1]!=0) {
      return(station.meta)
    } else {
      if (silent) print("No available stations for your selection")
      return(NULL)
    }
  }
}

test.select.station <- function() {

# RUN !
# Available ECA&D stations for the range of longitude between 0 and 10 deg. East, the range of latitude between 20 and 30 deg. North and for altitudes around 400m +/- 40 m
available.station <- select.station(lon = c(0,10),lat=c(20,30),src="ECA&D",alt=560,silent=FALSE)
print(available.station)

# Available stations for ECA&D data
available.station <- select.station(src="ECA&D")
print(available.station)

# Available stations for NACD data
available.station <- select.station(src="NACD")
print(available.station)

# Available stations for GHCN data
# Not Run !
available.station <- select.station(src="GHCN")
print(available.station)

# Available stations for Norway
available.station <- select.station(cntr="NORWAY")
print(available.station)

# Available stations for FRANCE
available.station <- select.station(cntr="FRANCE")
print(available.station)

# Available stations recording 2m-surface temperature
available.station <- select.station(param="t2m")
print(available.station)

# Available data sources for Oslo station
available.station <- select.station(stid=18700)
print(available.station)
# ....
}
