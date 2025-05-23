% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/regrid.R
\name{regrid}
\alias{regrid}
\alias{regrid.default}
\alias{regrid.field}
\alias{regrid.station}
\alias{regrid.matrix}
\alias{regrid.eof}
\alias{regrid.pca}
\alias{sparseMproduct}
\title{Regrid}
\usage{
regrid(x, is = NULL, ...)
}
\arguments{
\item{x}{a field object.}

\item{is}{A list holding the coordinates lon and lat, a field object, an eof
object, or a station object - for the latter three, the field x is
interpolated to the longitude/latitude held by is.}

\item{xo}{Old x-coordinates (longitudes)}

\item{yo}{Old y-coordinates (latitudes)}

\item{xn}{New x-coordinates (longitudes)}

\item{yn}{New y-coordinates (latitudes)}

\item{beta}{The matrix of interpolation weights}

\item{approach}{'station' or 'pca2station'. If 'pca2station', the stations
are turned into PCAs before regridding and then converted back to station
objects.}

\item{verbose}{If TRUE, print out diagnostics}
}
\value{
A field object
}
\description{
Fast transform data from one longitude-latitude grid to another through
bi-linear interpolation. The regridding is done by first calculating a set
of weights. This is a "QUICK & DIRTY" way of getting approximate results.
More sophisticated methods exist (e.g. Kriging - LatticeKrig).
}
\details{
Let X(i,j) be a i-j matrix containing the data on a grid with i logitudes
and j latitudes. We want to transform this to a different grid with k
longitudes and l latitudes:

X(i,j) -> Y(k,l)

First the routine computes a set of weight, then performs a matrix
multiplication to map the original data onto the new grid.  The weights are
based on the distance between points, taking longitude & latitude and use
distAB() to estimate the geographical distance in km.

The matrix operation is: Y = beta X

beta is a matrix with dimensions (i*j,k*l)

( Y(1,1) ) (beta(1,1), beta(2,1), beta(3,1), ... ) ( X(1,1) ) ( Y(1,2) ) =
(beta(1,2), beta(2,2), beta(3,2), ... ) ( X(1,2) ) ( .....  ) (beta(1,3),
beta(2,3), beta(3,3), ... ) ( X(1,3) )

Most of the elements in Beta are zero!
}
\examples{

# Use regrid to interpolate to station location:
t2m <- t2m.DNMI()
data(Oslo)
z.oslo <- regrid(t2m,is=Oslo)
plot(Oslo)
lines(z.oslo)

# Regrid t2m onto the grid of the gcm
gcm <- t2m.NorESM.M()
Z <- regrid(t2m,is=gcm)
map(Z)

# Example using regrid on a matrix object:
t2m.mean <- as.pattern(t2m,FUN='mean')
z <- regrid(t2m.mean,is=list(lon=seq(min(lon(t2m)),max(lon(t2m)),by=0.5),
                             lat=seq(min(lat(t2m)),max(lat(t2m),by=0.5))))
image(lon(z),lat(z),z)
# Add land borders on top
data(geoborders)
lines(geoborders)

\dontrun{
## Regrid station data using weights defined by the distance of the 4
## nearest stations: quick and dirty method
if (!file.exists("stationsVALUE_exp1a.rda")) {
  download.file("http://files.figshare.com/2085591/value_predictands4exp1a.R",
                "value_predictands4exp1a.R")
  source("value_predictands4exp1a.R")
}
   
load("stationsVALUE_exp1a.rda")
TX <- regrid(Tx,is=list(lon=seq(-8,30,by=1),lat=seq(40,60,by=0.5)))
map(TX)
}

}
\seealso{
aggregate.grid
}
\author{
R.E. Benestad and A. Mezghani
}
\keyword{utilities}
