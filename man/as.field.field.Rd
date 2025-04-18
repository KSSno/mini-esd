% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/as.field.R
\name{as.field.field}
\alias{as.field.field}
\title{Coerce input to a \code{field} object}
\usage{
\method{as.field}{field}(x, verbose = FALSE, ...)
}
\arguments{
\item{x}{the input object of class \code{field}}

\item{verbose}{a boolean; if TRUE print information about progress}

\item{...}{other arguments}
}
\value{
a \code{field} object
}
\description{
Transform an input object into the esd class \code{field}. If the input is a combined field, redirect to \code{as.field.comb}, else return input.
}
\seealso{
as.field as.field.comb
}
