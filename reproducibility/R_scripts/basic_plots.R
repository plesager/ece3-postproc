#!/usr/bin/env Rscript

# Some basic plots of time series 
# 
# F. Massonnet
# November 2017

library(ncdf4)
source("./compute_extent.R")
source("./compute_cellarea.R")


args = commandArgs(trailingOnly=TRUE)
# test if there are the correct number of arguments: if not, return an error
if (length(args)<7) {
  stop("basic_plots.R: You should use 7 arguments: data location, plots location, exp1, exp2, year1, year2 and the number of members, (option) skip sea ice", call.=FALSE)
}

path=args[1]
plotdir=args[2]
exp1=args[3]
exp2=args[4]
year1=args[5]
year2=args[6]
nmemb=args[7]

dosice=TRUE
if (length(args)==8) { dosice=FALSE }

exps = c(exp1, exp2)
n.memb <- strtoi(nmemb)
yearb <- strtoi(year1)
yeare <- strtoi(year2)

#====
n.exp <- length(exps)
colors <- c(rgb(1, 0.5, 0.0), rgb(0.0, 0.5, 0.0))
n.month <- 12
hemi <- c('N', 'S')
n.hemi <- 2
n.year <- yeare - yearb + 1
l_readgrid <- TRUE

sie <- array(NA, dim = c(n.exp, n.hemi, n.memb, n.year, n.month))
mst <- array(NA, dim = c(n.exp,         n.memb, n.year, n.month))
tp  <- array(NA, dim = c(n.exp,         n.memb, n.year, n.month))

for (j.exp in seq(1, n.exp)) {
  print(paste("Reading data from ensemble: ",exps[j.exp]))
  for (j.memb in seq(1, n.memb)) {
    fcmemb <- paste(exps[j.exp], j.memb, sep = "")

    if (dosice) {
        ## SEA ICE
        filein <- (paste(path, "/", exps[j.exp], j.memb, '/post/clim-',year1,'-',year2,'/SICE_mon_2x2.nc',sep=""))
        f <- nc_open(filein) 
        sic <- ncvar_get(f, 'ci')

        ## hack
        sic <- pmax(sic,0)
        sic <- pmin(sic,1)

        lat <- ncvar_get(f, 'latitude')
        lon <- ncvar_get(f, 'longitude')
        tmp <- compute_cellarea(lon, lat)
        lon <- tmp$lon
        lat <- tmp$lat
        cellarea <- tmp$cellarea
        nc_close(f)

        j.t <- 1
        year <- yearb
        j.month <- 1
        for (j.t in seq(1, dim(sic)[3])) {
            sie[j.exp, 1, j.memb, year- yearb + 1, j.month] <- compute_extent(sic[, , j.t], lon, lat, cellarea, lsmask=NULL, sector="N")
            sie[j.exp, 2, j.memb, year- yearb + 1, j.month] <- compute_extent(sic[, , j.t], lon, lat, cellarea, lsmask=NULL, sector="S")
      
            j.month = j.month + 1
            if (j.month > 12){
                j.month <- 1
                year = year + 1
            }
        }
    }

    # T2M
    filein <- (paste(path, "/", exps[j.exp], j.memb, '/post/clim-',year1,'-',year2,'/t2m_mon_2x2.nc',sep=""))
    f <- nc_open(filein)
    tas <- ncvar_get(f, 'tas')
    lat <- ncvar_get(f, 'latitude')
    lon <- ncvar_get(f, 'longitude')
    tmp <- compute_cellarea(lon, lat)
    lon <- tmp$lon
    lat <- tmp$lat
    cellarea <- tmp$cellarea
    nc_close(f)

    j.t <- 1
    year <- yearb
    j.month <- 1
    for (j.t in seq(1, dim(tas)[3])) {
      mst[j.exp, j.memb, year- yearb + 1, j.month] <- sum(tas[, , j.t] * cellarea) / sum(cellarea)

      j.month = j.month + 1
      if (j.month > 12){
        j.month <- 1
        year = year + 1
      }
    }
    
    # PRECIP
    filein <- (paste(path, "/", exps[j.exp], j.memb, '/post/clim-',year1,'-',year2,'/tp_mon_2x2.nc',sep=""))
    f <- nc_open(filein)
    totp <- ncvar_get(f, 'totp') 
    lat <- ncvar_get(f, 'latitude')
    lon <- ncvar_get(f, 'longitude')
    tmp <- compute_cellarea(lon, lat)
    lon <- tmp$lon
    lat <- tmp$lat
    cellarea <- tmp$cellarea
    nc_close(f)

    j.t <- 1
    year <- yearb
    j.month <- 1
    for (j.t in seq(1, dim(totp)[3])) {
      tp[j.exp,  j.memb, year - yearb + 1, j.month] <- sum(totp[, , j.t] * cellarea )

      j.month = j.month + 1
      if (j.month > 12){
        j.month <- 1
        year = year + 1
      }
    }

  }
}

if (dosice) {
    ## Plot sea ice mean & envelopes
    me <- apply(sie, c(1, 2, 4, 5), mean)
    ub <- apply(sie, c(1, 2, 4, 5), max)
    lb <- apply(sie, c(1, 2, 4, 5), min)
    for (j.hemi in seq(1, n.hemi)) {
        for (j.month in seq(1, n.month)) {
            setEPS()
            postscript(paste(plotdir, "/series_", exp1, "_", exp2, "_sie_", hemi[j.hemi], '_m',
                             sprintf("%02d", j.month), '.eps', sep = ""), width = 5, height = 4)
            plot(NaN, NaN, xlim = c(yearb, yeare), 
                 ylim = c(min(lb[, j.hemi, , j.month], na.rm = TRUE), 
                          max(ub[, j.hemi, , j.month], na.rm = TRUE)),
                 xlab = 'Years', ylab = 'Million km²',
                 main = paste("Sea ice extent ", hemi[j.hemi], " m", sprintf("%02d", j.month), sep = ""))

            for (j.exp in seq(1, n.exp)) {
                lines(seq(yearb, yeare), me[j.exp, j.hemi, , j.month], col = colors[j.exp], lwd = 5)
                lines(seq(yearb, yeare), ub[j.exp, j.hemi, , j.month], col = colors[j.exp], lwd = 1, lty = 2)
                lines(seq(yearb, yeare), lb[j.exp, j.hemi, , j.month], col = colors[j.exp], lwd = 1, lty = 2)
                text(yeare, max(ub[, j.hemi, , j.month]) - j.exp, exps[j.exp], col = colors[j.exp], pos = 2)
            }
            dev.off()
        }
    } 
}

# Plot mst in annual mean envelopes
mst_anmean <- apply(mst, c(1, 2, 3), mean)
lb <- apply(mst_anmean, c(1, 3), min, na.rm = TRUE)
ub <- apply(mst_anmean, c(1, 3), max, na.rm = TRUE)
me <- apply(mst, c(1, 3), mean, na.rm = TRUE)

setEPS()
postscript(paste(plotdir, "/series_", exp1, "_", exp2, "_tas.eps", sep = ""), width = 5, height = 4)
plot(NaN, NaN, xlim = c(yearb, yeare), ylim = c(min(lb), max(ub)), 
    ylab = '°C', xlab = 'Years' )
for (j.exp in seq(1, n.exp)) {
  lines(seq(yearb, yeare), me[j.exp, ], col = colors[j.exp], lwd = 5)
  lines(seq(yearb, yeare), ub[j.exp, ], col = colors[j.exp], lwd = 1, lty = 2)
  lines(seq(yearb, yeare), lb[j.exp, ], col = colors[j.exp], lwd = 1, lty = 2)
}
dev.off()

# Plot totp in annual mean envelopes
mtp <- apply(tp, c(1, 2, 3), mean) * (365 * 86400)
me <- apply(mtp, c(1, 3), mean)
lb <- apply(mtp, c(1, 3), min)
ub <- apply(mtp, c(1, 3), max)

setEPS()
postscript(paste(plotdir, "/series_", exp1, "_", exp2, "_totp.eps", sep = ""), width = 5, height = 4)
plot(NaN, NaN, xlim = c(yearb, yeare), ylim = c(min(lb), max(ub)),
    ylab = 'kg', xlab = 'Years' )
for (j.exp in seq(1, n.exp)) {
  lines(seq(yearb, yeare), me[j.exp, ], col = colors[j.exp], lwd = 5)
  lines(seq(yearb, yeare), ub[j.exp, ], col = colors[j.exp], lwd = 1, lty = 2)
  lines(seq(yearb, yeare), lb[j.exp, ], col = colors[j.exp], lwd = 1, lty = 2)
}
dev.off()


