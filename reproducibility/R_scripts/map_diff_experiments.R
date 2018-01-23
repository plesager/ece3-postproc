#!/usr/bin/env Rscript

## We test the statistical difference between two ensembles of experiments for several variables.
## Adapted for for the ece3-postproc tools suite package; replace obsolete
## ncdf with ncdf4 (PLS, Jan 2018) 

library(ncdf4)
library(s2dverification)
library(RColorBrewer)

args = commandArgs(trailingOnly=TRUE)

## test if there are the correct number of arguments: if not, return an error
if (length(args)!=6) {
    stop("You should use 6 arguments: the path where is located the data, exp1, exp2, year1, year2 and the number of members", call.=FALSE)
}

path=args[1]
exp1=args[2]
exp2=args[3]
year1=args[4]
year2=args[5]
nmemb=args[6]

var_name=c('t2m','msl','qnet','tp','ewss','nsss','SICE')
var_name2=c('tas','msl','str','totp','ewss','nsss','ci')
nb_var=length(var_name)

for (ji in 1:nb_var) {

    var=var_name[ji]
    var2=var_name2[ji]

    writeLines(paste("\n** Processing:",var))

    exp_name=array(dim=2)
    exp_name[1]=exp1
    exp_name[2]=exp2

    ## Opening the files and reading the data
    for (jexp in 1:2) {
        for (jmemb in 1:nmemb) {

            fnc <- nc_open(paste(path, "/", exp_name[jexp], jmemb, '/post/clim-',year1,'-',year2,'/',var,'_mon_2x2.nc',sep=""))
            lon <-  ncvar_get(fnc, varid='longitude')
            lat <-  ncvar_get(fnc, varid='latitude')
            time <- ncvar_get(fnc, varid='time')

            if (jmemb == 1 && jexp==1 ) {
                data=array(NaN,dim=c(2,nmemb,length(lon),length(lat),length(time)))
            }
            
            writeLines(paste("       reading experiment ",exp_name[jexp]," and member ",jmemb,sep=""))
            writeLines(paste("       number of longitudes=",length(lon),sep=""))
            writeLines(paste("       number of latitudes=",length(lat),sep=""))

            if (dim(lon)==dim(data)[3] && dim(lat)==dim(data)[4]) {
                writeLines("       dimensions OK")
            } else {
                writeLines(paste("       bad dimensions for exp ",exp_name[jexp],' and memb ',memb_name[jmemb],sep=""))
            } 
            
            ## Get the variable:
            data[jexp,jmemb,,,] <- ncvar_get(fnc,varid=var2)

            ## Closing netcdf file:
            nc_close(fnc)
        }
    }

    writeLines(paste("    computing means for",var,'...\n'))

    ## Mean and differences:
    mean_data <- Mean1Dim(data,posdim=5)
    if (dim(data)[5] == 1 ) {
        mean_exp1 <- data[1,,,,]
        mean_exp2 <- data[2,,,,]
    } else {
        mean_exp1 <- Mean1Dim(data[1,,,,],posdim=4)
        mean_exp2 <- Mean1Dim(data[2,,,,],posdim=4)
    }

    ## We map the differences between exp1 and exp2. In the future, it could be possible to compare three o more experiments
    diff_exp1_exp2 <- Mean1Dim(mean_exp1,posdim=1)-Mean1Dim(mean_exp2,posdim=1)

    ## Kolmogorov-Smirnov test:
    test_exp1_exp2 <- apply(mean_data,c(3,4),function(x) if (ks.test(x[1,],x[2,])$p.value < 0.05) {1} else {0})
    p_value <- apply(mean_data,c(3,4),function(x) ks.test(x[1,],x[2,])$p.value)

    ## % of grid point where the difference is significant:
    percent=round(sum(test_exp1_exp2)/length(test_exp1_exp2)*100)

    ## We save data before generating maps (it can be used to redo the maps with other colour levels for example)
    save(var,diff_exp1_exp2,lon,lat,test_exp1_exp2,percent,file=paste(path,"/save_",var,".RData",sep=""))

    ## Maps
    ##if (var == 't2m') {brks <- def=c(-5,-2.5,-1,-0.5,-0.25,0,0.25,0.5,1,2.5,5)}
    ##if (var == 'qnet') {brks <- def=c(-50,-25,-10,-5,-1,0,1,5,10,25,50)}
    ##if (var == 'SICE') {brks <- def=c(-1,-0.001,0.001,1)}
    ## Automatic levels for the colour bar:
    brks_max=max(abs(diff_exp1_exp2))
    brks_def=seq(-brks_max,brks_max,brks_max/5.)
    jBrewColors <- brewer.pal(n=length(brks_def)-1,name='RdBu')
    postscript(paste(path,'/diff_',exp1,'_',exp2,'_',var,'.eps',sep=""))

    PlotEquiMap(diff_exp1_exp2,lon,lat,toptitle=paste(var," difference between ",nmemb,"-member experiments ",exp1," and ",exp2,". Black doted regions indicate where the difference \n is significant according to a Kolmogorov-Smirnov test (",percent,"% of grid points show a significant difference)",sep=""),
                sizetit = 0.5, units = "",
                brks=brks_def, cols=rev(jBrewColors),
                square = TRUE, filled.continents = FALSE, contours = NULL, brks2 = NULL,
                dots = test_exp1_exp2, axelab = TRUE, labW = FALSE, intylat = 20, intxlon = 20,
                drawleg = TRUE, subsampleg = 1, numbfig = 1, colNA = "white")

    dev.off()

    ## Plot the p <- value:

    brks_def=c(0,0.0001,0.001,0.01,0.05,0.1,0.5,1)
    jBrewColors <- brewer.pal(n=length(brks_def)-1,name='RdBu')
    postscript(paste(path,'/p_value_diff_',exp1,'_',exp2,'_',var,'.eps',sep=""))

    PlotEquiMap(p_value,lon,lat,toptitle=paste(var," p_value when comparing the difference between ",nmemb,"-member experiments ",exp1," and ",exp2," according to a Kolmogorov-Smirnov test",sep=""),
                sizetit = 0.5, units = "",
                brks=brks_def, cols=rev(jBrewColors), square = TRUE,
                filled.continents = FALSE, contours = NULL, brks2 = NULL,
                dots = NULL, axelab = TRUE, labW = FALSE, intylat = 20, intxlon = 20,
                drawleg = TRUE, subsampleg = 1, numbfig = 1, colNA = "white")

    dev.off()
}

