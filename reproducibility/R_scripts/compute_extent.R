compute_extent <- function(sic, lon, lat, cellarea, lsmask=NULL, sector="N"){
  # François Massonnet (2015)
  #
  # Computes sea ice extent from sea ice concentration field, land-sea mask and area.
  # Definition of sea ice extent follows National Snow and Ice Data Center (NSIDC):
  # Sea ice extent is the cumulated area of *grid cells* covered by at least 15% of ice
  # Example: cell 1 is 100 m2 and is covered by 20% of ice
  #          cell 2 is 50  m2 and is covered by 50% of ice
  #          cell 3 is 200 m2 and is covered by 10% of ice
  # 
  #          extent = 100 m2 + 50 m2 = 150 m2
  #
  #          Note that sea ice area, in this example, would be 65 m2
  #          Note finally that there exists another, yet unused definition of sea ice
  #          extent, as the cumulated area of *ice* in grid cells covered by at least
  #          15% of ice. This modified extent would be 45 m2. It is *not* the one considered
  #          here.
  # 
  # Mandatory inputs:
  # -----------------
  # * sic      is a 2-D array of sea ice concentration expressed in [0,1]
  # * lon      is a 2-D array of longitudes,       with the same dimensions as sic
  #              Units: degrees, in [-180,180] or [0,360]
  # * lat      is a 2-D array of latitudes,        with the same dimensions as sic
  #              Units: degrees, in [-90,90]
  # * cellarea is a 2-D array of grid cell areas,  with the same dimensions as sic
  #              Units: squared meters
  # 
  #  If your grid is *regular* (lon is the same regardless of latitude and vice-versa)
  #  it is possible to create 2-D arrays for lon, lat and cellarea using the 
  #  compute_cellarea function.

  # Optional inputs:
  # ----------------
  # * lsmask   is a 2-D array of land-sea mask: zero on land, one over sea
  #              This mask should be available from the producer of the data
  #              If no input is given, the whole domain is supposed to be covered
  #              by sea.
  # * sector   is a string describing the sector where the calculation must be performed.
  #            Currently: 	N 		Northern Hemisphere
  #				S		Southern Hemisphere
  #				Barents		Barents Sea
  #				AmBel		Amundsen-Bellingshausen Seas
  # 				Weddell		Weddell Sea
  # 				Ross		Ross Sea


  # Output:
  # -------
  # The script returns sea ice extent over the sector provided, following the definition above,
  # in units of million km2.

  # ~~~~~~~~~~
  # SCRIPT 
  # ~~~~~~~~~~

  # Make sure we have 2-D arrays
  if ( length(dim(lon)) != 2 | length(dim(lat)) != 2) {
    stop("compute_extent.R: longitude and/or latitude is not 2-dimensional")
  }

  # Get the dimensions of the grid
  nx <- dim(lon)[1]
  ny <- dim(lon)[2]

  # Check that the data, longitude, latitude, cell area dimensions match 
  if ( (
        dim(sic)[1]      != nx | dim(sic)[2]      != ny | 
        dim(lat)[1]      != nx | dim(lat)[2]      != ny |
        dim(cellarea)[1] != nx | dim(cellarea)[2] != ny  
       ) 
     ) {
    print(paste("compute_extent.R: dim(sic) = ",toString(dim(sic)[1]),'x',toString(dim(sic)[2]),sep=""))
    print(paste("compute_extent.R: dim(lon) = ",toString(dim(lon)[1]),'x',toString(dim(lon)[2]),sep=""))
    print(paste("compute_extent.R: dim(lat) = ",toString(dim(lat)[1]),'x',toString(dim(lat)[2]),sep=""))
    print(paste("compute_extent.R: dim(cellarea) = ",toString(dim(cellarea)[1]),'x',toString(dim(cellarea)[2]),sep=""))
    stop("compute_extent.R: Problem with the dimensions of the input data: no match")
  }
  # Check the mask has the right dimensions (if it was provided)
  if ( ! is.null(lsmask) ) {
    if ( dim(lsmask)[1] != nx | dim(lsmask)[2] != ny ){
      print(paste("compute_extent.R: dim(sic) = ",toString(dim(sic)[1]),'x',toString(dim(sic)[2]),sep=""))
      print(paste("compute_extent.R: dim(lsmask) = ",toString(dim(lsmask)[1]),'x',toString(dim(lsmask)[2]),sep=""))
      stop("compute_extent.R: Problem with the dimensions of the input data: no match")
    }
  }

# If the array is full of NA (which can happen if the satellite did not pass
# over the region), then return NA
if (prod(dim(sic)) == sum(is.na(sic))){
  return(NA)
}

# Regularization of longitudes, check the validity of data
# --------------------------------------------------------
lon[lon > 180] <- lon[lon > 180] - 360
if ( max(lon)> 180 | min(lon) < -180){
  stop("compute_extent.R: Something is weird with the input longitudes. Are they well in degrees?")
}

if ( max(lat) > 90 | min(lat) < -90 ){
  stop("compute_extent.R: Something is weird with the input latitudes. Are they well in degrees?")
}

# Handle the mask
# ---------------
if ( is.null(lsmask) ){
  lsmask <- array(1,dim=c(nx,ny))
} else {
  if (max(lsmask) > 1 | min(lsmask) < 0){
    stop("compute_extent.R: Mask values are not in [0,1]")
  }
}


# Compute area of the domain, to check everything OK
# --------------------------------------------------
#print(paste("compute_extent.R: total area of the masked domain provided is ",sum(cellarea*lsmask)/1e12," million km2 (Earth's surface: ~510 million km2)",sep=""))


# Determine the sector and boundaries.
# ------------------------------------
# latmin is always less than latmax.
# lon max is always larger than lonmin, except if the boundary crosses the 180° meridian. 
# In this latter case lonmin is larger (e.g. 170°) than lonmax (e.g.-170°)
switch( sector,
  # Northern Hemisphere
  N        = { lonmin <- -Inf; lonmax <- Inf ; latmin <-  0   ; latmax <- Inf},
  N_AtlS1  = { lonmin <- -95 ; lonmax <- 140 ; latmin <-  0   ; latmax <- Inf},
  N_Atl    = { lonmin <- -95 ; lonmax <- 135 ; latmin <-  0   ; latmax <- Inf},
  N_PacS1  = { lonmin <- 140 ; lonmax <- -95 ; latmin <-  0   ; latmax <- Inf},
  N_Pac    = { lonmin <- 135 ; lonmax <- -95 ; latmin <-  0   ; latmax <- Inf},
  N_Barents = { lonmin <- 18  ; lonmax <- 70  ; latmin <- 68   ; latmax <- 82 },
  # Southern Hemisphere
  S         = { lonmin <- -Inf; lonmax <- Inf ; latmin <- -Inf ; latmax <- 0  },
  S_Weddell = { lonmin <- -60 ; lonmax <- 20  ; latmin <- -Inf ; latmax <- 0  },
  S_Indian  = { lonmin <- 20  ; lonmax <- 90  ; latmin <- -Inf ; latmax <- 0  },
  S_Pacific = { lonmin <- 90  ; lonmax <- 160 ; latmin <- -Inf ; latmax <- 0  },
  S_Ross    = { lonmin <- 160 ; lonmax <- -130; latmin <- -Inf ; latmax <- 0  },
  S_AmBel   = { lonmin <- -130; lonmax <- -60 ; latmin <- -Inf ; latmax <- 0  },
  stop("compute_extent.R: sector unknown")
)

# Detect a possible mismatch between the lat/lon and the sector requested
# -----------------------------------------------------------------------
if ( max(lat) < latmin | min(lat) > latmax  ) {
  stop("compute_extent.R: It seems that your domain is not included in the range of longitudes and latitudes provided")
}

# Detect if the data is weird
# ---------------------------
if (max(sic, na.rm = T) > 1) {
  stop("compute_extent.R: Sea ice concentration as provided is not in [0, 1]")
}
# Compute sea ice extent
# ----------------------
# 1. Create geographical mask based on region provided

if (lonmin > lonmax) { # boundary straddling the 180 meridian
  masksector <- 1* ( (lon > lonmin | lon < lonmax) & (lat > latmin & lat < latmax))
} else {
  masksector <- 1* ( (lon > lonmin & lon < lonmax) & (lat > latmin & lat < latmax))
}

# 2. Ice mask: only keep grid cells with icesic > 0.15 and less than 1
maskice <- 1* (sic>0.15 & sic<= 1.)

# 3. Ice extent: the sum of grid cell areas where conditions 1. and 2. are met, and where it's not land
iceextent <- sum(cellarea * maskice * masksector * lsmask ,na.rm=TRUE) / 1e12 # to get million km2

return(iceextent)

}


