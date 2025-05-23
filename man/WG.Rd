% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/WG.R
\name{WG}
\alias{WG}
\alias{WG.station}
\alias{WG.fwmu.day.precip}
\alias{WG.FT.day.t2m}
\alias{WG.pca.day.t2m.precip}
\alias{FTscramble}
\title{Weather generators for conditioned on simulated climate aggregated
statistics.}
\usage{
WG(x, ...)
}
\arguments{
\item{x}{station object}

\item{\dots}{additional arguments}

\item{option}{Define the type of WG}

\item{amean}{annual mean values. If NULL, use those estimated from x; if NA,
estimate using \code{\link{DSensemble.t2m}}, or if provided, assume a
'dsensemble' object.}

\item{asd}{annual standard deviation. If NULL, use those estimated from x;
if NA, estimate using \code{\link{DSensemble.t2m}}, or if provided, assume a
'dsensemble' object.}

\item{t}{Time axis. If null, use the same as x or the last interval of same
length as x from downscaled results.}

\item{ip}{passed on to \code{\link{DSensemble.t2m}}}

\item{select}{passed on to \code{\link{DSensemble.t2m}}}

\item{lon}{passed on to \code{\link{DSensemble.t2m}}}

\item{lat}{passed on to \code{\link{DSensemble.t2m}}}

\item{plot}{if TRUE, plot results}

\item{biascorrect}{passed on to \code{\link{DSensemble.t2m}}}

\item{verbose}{passed on to \code{\link{DSensemble.t2m}}}

\item{mu}{annual wet-mean values. If NULL, use those estimated from x; if
NA, estimate using \code{\link{DSensemble.t2m}}, or if provided, assume a
'dsensemble' object.}

\item{fw}{annual wet-day frequency. If NULL, use those estimated from x; if
NA, estimate using \code{\link{DSensemble.t2m}}, or if provided, assume a
'dsensemble' object.}

\item{ndd}{annual mean dry spell length. If NULL, use those estimated from
x; if NA, estimate using \code{\link{DSensemble.t2m}}, or if provided,
assume a 'dsensemble' object.}

\item{threshold}{Definition of a rainy day.}

\item{method}{Assume a gemoetric or a poisson distribution. Can also define
ownth methods.}

\item{t2m}{station object with temperature}

\item{precip}{station object with precipitation.}

\item{ndbr}{Number of}

\item{n.spells.year}{= c('fw','spell') if 'fw' then estimate number of spells according to 365.25 else estimate number of events from \code{\link{spell}}.}

\item{alpha.scaling}{TRUE scale the low-probability events according to alpha in DOI:10.1088/1748-9326/ab2bb2}

\item{alpha}{values for alpha-scaling}

\item{ensure.fw}{TRUE then WG tries to ensure that fw of simulations match those of observations or prescribed by adding or subtracting wet days.}

\item{w.fw.ac}{weighting to balance how the wet day occurrences follows seasonal cycle or randomness. 0 - no seasonal cycle; 1000 - mainly determined by climatology (default=30).}

\item{w.mu.ac}{same as above, but for wet-day mean precipitation (default=10).}
}
\description{
Weather generators for conditional simulation of daily temperature and/or
precipitation, given mean and/or standard deviation. The family of WG
functions produce stochastic time series with similar characteristics as the
station series provided (if none if provided, it will use either ferder or
bjornholt provided by the esd-package). Here characteristics means similar
mean value, standard deviation, (frequency and wet-day mean precipitation for 
precipitation), and spectral properties. \code{FTscramble}
takes the Fourier components (doing a Fourier Transform - FT) of a series 
and reassigns random phase to each frequency and then returns a new series 
through an inverse FT. The FT scrambling is used for temperature, but not for 
daily precipitation that is non-Gaussian and involves sporadic events with rain. 
Instead, \code{FTscramble} is used for randomly scrambling annual wet-day frequency 
and wet-day mean precipitation, however, and for precipitation, the annual wet-day
frequency and the annual wet-day mean precipitation are used to randomly generate
exponentially distributed numbers to provide similar aggregated annual
statistics as the station or predicted though downscaling. The precipitation
WG can also take into account the number of consecutive number-of-wet-days
statistics using a geometric distribution.
}
\details{
The weather generator produces a series with similar length as the provided
sample data, but with shifted dates according to specified scenarios for
annual mean mean/standard deviation/wet-day mean/wet-day frequency.

\code{WG.FT.day.t2m} generates daily temperature from seasonal means and
standard deviations. It is given a sample station series, and uses
\code{FTscramble} is based on a Fourier Transform which generates a new series 
with random phase but nevertheless similar (or predicted - in the future) spectral 
characteristics as the original series. It then uses a quantile
transform to prescribe predicted mean and standard deviation, assuming the
distributions are normal, which usually is OK for seasonall/annually aggregated statistics 
(e.g. annual mean, annual wet-day frequency, or annual wet-day mean precipitation). 
The temporal structure (power spectrum) of the random series is therefore similar 
as the sample provided.

\code{WG.fwmu.day.precip} has been designed to be used with downscaled results for 
annual wet-day frequency and annual wet-day mean precipitation. It also tries to
simulate the wet-spell duration statistics (number of consecutive wet days) based on
provided sample data (argument x). The process can take annual wet-day mean precipitation 
and the wet-day frequency as input when used to make projections for the future, together 
with a sample station of daily values, to simulate stochastic numbers of consecutive 
wet days, based on its annual mean number of consecutive wet days. It also uses 
the mean annual cycle of wet-day frequency as well as the wet-day mean precipitation 
to guide the seasonal timing of wet days and amounts, and hence tries to mimic rain seasons. 
If not specified, it is taken from the sample data after being phase scrambled/shuffled 
(\code{FTscramble} - a bit like a deck of cards). If not specified, the annual wet-day 
frequency is a phase-scrambled version of annual aggregates from the sample data. The daily 
amount is taken from stochastic values generated with \code{\link{rexp}} scaled 
for the tail according to alpha in (described in DOI: 10.1088/1748-9326/ab2bb2) 
as in \code{\link{day2IDF}}. The number of consecutive wet days is approximated 
by a geometric distribution (\code{\link{rgeom}}), and the annual number of wet days 
is either given as input or estimated from the sample series. 
\code{test.WG.fwmu.day.precip} presents diagnostics of tests of \code{WG.fwmu.day.precip}.
}
\examples{
## Temperature
data(ferder)
x <- WG(ferder)
## Plot the results
plot(merge(ferder,x), xlab='', ylab=c('Obs T2m','WG T2m'), col='blue', main=paste(loc(x),' Obs/WG'))

## Daily precipitation
data(bjornholt)
z <- WG(bjornholt)
## Plot the results
plot(merge(bjornholt,z), xlab='', ylab=c('Obs precip','WG precip'), col='blue', main=paste(loc(z),' Obs/WG'))
sz <- sort(coredata(z)[index(z) \%in\% index(bjornholt)])
sy <- sort(coredata(bjornholt)[index(bjornholt) \%in\% index(z)])
## Use WG to 'simulate' climate change
z2 <- WG(bjornholt, mu=annual(bjornholt, FUN='wetmean') + 2)
sz2 <- sort(coredata(z2)[index(z2) \%in\% index(bjornholt)])

## Plot the comparison of quantiles
plot(sy, sz, pch=19, cex=0.7, main='QQ-plot', xlab='Observations', ylab='WG')
grid()
lines(c(0, max(sy,sz,na.rm=TRUE)), c(0,max(sy,sz,na.rm=TRUE)), lty=2, col='red')
points(sy, sz2, col='blue', cex=0.7)


## Simple simulation of contnued trends in wet-day mean precipitation and frequency
mu <- annual(bjornholt,FUN='wetmean',nmin=270) # Avoid missing values (NA)
fw <- annual(bjornholt,FUN='wetfreq',nmin=270) # Avoid missing values (NA)
mu.trend <- trend(mu)
fw.trend <- trend(fw)
## Construct precipitation statistics for input to WG
mu2 <- c(mu,zoo(coredata(mu)+coredata(max(mu.trend)-min(mu.trend)),order.by=max(index(mu))+1:length(mu)))
fw2 <- c(fw,zoo(coredata(fw)+coredata(max(fw.trend)-min(fw.trend)),order.by=max(index(fw))+1:length(fw)))
z <- WG(bjornholt,mu=mu2,fw=fw2,verbose=TRUE)
plot(z)

#' ## Test the WG
z2 <- WG(bjornholt,w.mu.ac=1000,plot=TRUE,verbose=TRUE)
plot(aggregate(z2,by=month,FUN='wetmean')); lines(aggregate(bjornholt,by=month,FUN='wetmean'))
z3 <- WG(bjornholt,w.fw.ac=1000,plot=TRUE,verbose=TRUE)
plot(aggregate(z3,by=month,FUN='wetfreq')); lines(aggregate(bjornholt,by=month,FUN='wetfreq'))

## Test-routine for WG
test.WG.fwmu.day.precip()
}
\author{
R.E. Benestad
}
\keyword{manip}
