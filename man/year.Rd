% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/year.R
\name{year}
\alias{year}
\alias{month}
\alias{day}
\title{Conversion to esd objects.}
\usage{
year(x, verbose = FALSE)
}
\arguments{
\item{x}{an object of, e.g., class 'station', 'field', or 'zoo', or a date}
}
\value{
a numeric for \code{year}, \code{month}, and \code{day}; A numeric or character for \code{season}
}
\description{
\code{year}, \code{month}, \code{day}, \code{season} return the years, months, days, and seasons
associated with the data.
}
\examples{
data(bjornholt)
year(bjornholt)
month(bjornholt)
day(bjornholt)
season(bjornholt)
season(bjornholt, format="numeric")

}
\seealso{
season season.default
}
\keyword{utilities}
