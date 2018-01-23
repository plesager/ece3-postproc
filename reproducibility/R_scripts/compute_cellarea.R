#!/bin/bash
# François Massonnet (2015)
#
# Computes grid cell areas for a *regular* grid given the lon and lat vectors
# lon and lat are assumed to have uniform step. If they don't, the steps are estimated using linear interpo-
# lation. lat can be given in ascending or descending order.
# 
# Inputs: 
#          lon  , a 1-D vector of length ny, expressed in degrees
#          lat  , a 1-D vector of length nx, expressed in degrees
# Outputs:
#          LON      , a 2-D matrix of dimensions (ny,nx). Each column of LON is lon
#          LAT      , a 2-D matrix of dimensions (ny,nx). Each row    of LAT is lat
#          cellarea , a 2-D matrix of dimensions (ny,nx). Each entry of cellarea has the area of the grid cell
#                     located at the corresponding (LON,LAT) coordinates. Units are squared meters.        
#
# Note: lat is not supposed to be sorted, but can be. In any case, the function returns the array that matches
# the ordering of lat.
#
# The function is based on the mean radius of Earth taken equal to 6371 km (Google et al., 2015)

compute_cellarea <- function(lon, lat){

if ( length(dim(lat)) > 1 | length(dim(lon)) > 1){
  stop("compute_cellarea.R: problem: lon or lat is not 1D")
}

nx <- length(lat)
ny <- length(lon)

#print(paste("Grid dimensions are ",toString(nx), " (north-south) and ",toString(ny), " (east-west)",sep=""))

# Check that the step is consistent
stepslat_1d <- abs(lat[seq(2,nx)] - lat[seq(1,nx-1)])
stepslon_1d <- abs(lon[seq(2,ny)] - lon[seq(1,ny-1)])

if ( abs(max(stepslat_1d) - min(stepslat_1d) ) > 0.01 ) {
  print("compute_cellarea.R: problem: latitude steps are not uniform")
  print(paste("Maximum step is: ", toString(abs(max(stepslat_1d))), "°", sep = ""))
  print(paste("Minimum step is: ", toString(abs(min(stepslat_1d))), "°", sep = ""))
  print("Don't worry, this can happen")

  # We need to make an array with the steps
  # The idea is the following
  # Suppose 
  # lat =    [0   20 50 80 90  ]
  #
  # We need for each entry of the list to have the spacing corresponding to the grid point at that location
  # We construct
  # dlat_1 = [20  30 30 10 NaN ]
  # dlat_2 = [NaN 20 30 30 10  ]
  #
  # and estimate the spacing as
  # dlat   = [20  25 30 20 10  ]
  # (i.e. the arithmetic mean)
  # That's the best one can do, I think.

  dlat_1 <- array(NaN, dim = nx)
  dlat_2 <- array(NaN, dim = nx)
  dlat   <- array(NaN, dim = nx)
  
  dlat_1[seq(1, nx - 1)] <- abs( lat[seq(1, nx - 1)] - lat[seq(2, nx)])  # This one is of length nx - 1
  dlat_2[seq(2, nx    )] <- abs( lat[seq(1, nx - 1)] - lat[seq(2, nx)])  # Same vector of spacings

  dlat[1 ] <- dlat_1[1 ]
  dlat[nx] <- dlat_2[nx]
  dlat[seq(2, nx - 1)] <- 0.5 * (dlat_1[seq(2, nx - 1)] + dlat_2[seq(2, nx - 1)])

  stepslat <- array(NaN, dim = c(ny, nx))
  for (jy in seq(1, ny)) {
    for (jx in seq(1, nx)) {
      stepslat[jy, jx] <- dlat[jx]
    }
  }
} else {
  stepslat <- array(NaN, dim = c(ny, nx))
  for (jy in seq(1, ny)) {
    for (jx in seq(1, nx)) {
      stepslat[jy, jx] <- mean(stepslat_1d)  # Uniform steplat
    }
  }
}

if ( abs(max(stepslon_1d) - min(stepslon_1d) ) > 0.01  ) {
  print("compute_cellarea.R: problem: longitude steps are not uniform")
  print("Don't worry, this can happen")

  # See documentation above for explanations
  dlon_1 <- array(NaN, dim = ny)
  dlon_2 <- array(NaN, dim = ny)
  dlon   <- array(NaN, dim = ny)
  
  dlon_1[seq(1, ny - 1)] <- abs( lon[seq(1, ny - 1)] - lon[seq(2, ny)])  # This one is of length ny - 1
  dlon_2[seq(2, ny    )] <- abs( lon[seq(1, ny - 1)] - lon[seq(2, ny)])  # Same vector of spacings
  
  dlon[1 ] <- dlon_1[1 ]
  dlon[ny] <- dlon_2[ny]
  dlon[seq(2, ny - 1)] <- 0.5 * (dlon_1[seq(2, ny - 1)] + dlon_2[seq(2, ny - 1)])
  
  stepslon <- array(NaN, dim = c(ny, nx))
  for (jy in seq(1, ny)) {
    for (jx in seq(1, nx)) {
      stepslon[jy, jx] <- dlon[jy]
    } 
  }
} else {
  stepslon <- array(NaN, dim = c(ny, nx))
  for (jy in seq(1, ny)) { 
    for (jx in seq(1, nx)) {
      stepslon[jy, jx] <- mean(stepslon_1d)
    }
  }
}
# Expand the grid

LON <- array(NaN,dim=c(ny,nx))
LAT <- array(NaN,dim=c(ny,nx))

for (jy in seq(1,ny)){
  LAT[ jy ,  ]<-lat[seq(1,nx,1)]
}
for (jx in seq(1,nx)){
  LON[  , jx ]<- lon[seq(1,ny,1)]
}

# Compute area

# The quadrilateral comprised between two parallels and two meridians is a trapezoid: the two sides along parallels are ... parallel
# but the two sides along meridians are not, because they eventually meet at the pole.
#
# The LON and LAT matrices give the coordinates of the centre of the grid cells

# The area of a trapezoidal is (long base + small base)/2 * height
# The first term is the length of the parallel located at half distance (at latitude LAT, longitude LON)
Rearth <- 6371000 # Radius in m

cellarea <- Rearth * cos( (LAT * 2 * pi / 360 )) * (stepslon * 2 * pi / 360)  * Rearth * (stepslat * 2 * pi / 360)
#           -----------------------------------
#            Radius of earth at latitude LAT
#
#           ----------------------------------------------------------------
#                              Length of intercepted arc, along parallel
#                                                                              ------------------------------------
#                                                                              Length of intercepted arc, along meridian

# Check: total surface of earth
dev <- abs(sum(cellarea) - 510072000*10^6 )/(510072000*10^6)
#print(paste("The grid total area is ",toString(100*dev)," % different from Wikipedia Earth Surface",sep=""))
if ( dev  > 0.02){
  print("compute_cellarea.R: WARNING: Test failed for checking total area")
}

#return(cellarea)
invisible(list(lon=LON,lat=LAT,cellarea=cellarea))
}

