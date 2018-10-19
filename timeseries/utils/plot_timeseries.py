#!/usr/bin/env python3

doc=""" Plot timeseries of global averages (as computed by the timeseries tool
of ECE3_POST_PROC package) from one or more experiments.

!!! YOU MUST SET THE tsdir CONFIG IN THE SCRIPT !!!!

"""

import argparse
import os, sys, glob, re
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

# -- CONFIG: location of timeseries (same as ECE3_POSTPROC_DIAGDIR in your conf/<machine>/conf_timeseries_<machine>.sh)
tsdir='/home/ms/nl/nm6/ecearth3/diag/timeseries/'

parser = argparse.ArgumentParser(description=doc, formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument("exp", metavar='EXPi', nargs='+', help="id of each exp")
parser.add_argument('-l', "--label", nargs='+',     help="overwrite default legend in plots")
parser.add_argument("-p", "--pdf", help="will put all plots in one pdf file", action="store_true")
parser.add_argument("-f", "--fname", help="file name for pdf output"+
                    "(default: exp1_timeseries.pdf")
parser.add_argument("-a", "--ave", help="12-year moving average ONLY", action="store_true")

args = parser.parse_args()
pdf = args.pdf

print( "Plotting", len(args.exp), "experiments:", args.exp )

labels = list(args.exp)
if args.label:
    labels[:len(args.label)] = args.label 

# --- Availability for atmosphere

# for k in d1.data_vars:
#     print(k, d1[k].attrs['long_name'])

#  sfhf     Snowfall latent heat flux
#  sf       Snowfall
#  sshf     Surface sensible heat flux
#  slhf     Surface latent heat flux
#  str      Surface thermal radiation
#  ttr      Top thermal radiation
#  tas      Air temperature at 2m
#  msl      Mean sea level pressure
#  e        Evaporation
#  totp     Total precipitation
#  tcc      Total cloud cover
#  ssr      Surface solar radiation
#  tsr      Top solar radiation
#  PminE    P-E at the surface
#  NetTOA   TOA net heat flux
#  NetSFCs  Surface net heat flux with snowfall
#  NetSFC   Surface net heat flux
#
# --- Availability for ocean (tested on primavera case)
#
#  sosstsst            mean_sea_surface_temperature
#  sosaline            mean_sea_surface_salinity
#  sossheig            mean_sea_surface_height_above_geoid
#  sowaflup            mean_water_flux_into_sea_water
#  votemper            mean_sea_water_potential_temperature
#  votemper_3d         mean_3Dsea_water_potential_temperature
#  vosaline            mean_sea_water_salinity
#  vosaline_3d         mean_3Dsea_water_salinity
#  max_amoc_30N        Maximum of Atlantic MOC at 30N
#  max_amoc_40N        Maximum of Atlantic MOC at 40N
#  max_amoc_50N        Maximum of Atlantic MOC at 50N
#  tot_area_ice_north  sea_ice_area_fraction
#  tot_area_ice_south  sea_ice_area_fraction

# -- limited to those of interest

atm_wanted=['tas', 'msl', 'e', 'totp', 'tcc', 'ssr', 'tsr',
            'PminE', 'NetTOA', 'NetSFCs', 'NetSFC' ]
    
oce_wanted = ['sosstsst', 'sosaline', 'sossheig', 'votemper_3d',
              'vosaline_3d', 'max_amoc_30N', 'max_amoc_40N',
              'max_amoc_50N', 'tot_area_ice_north', 'tot_area_ice_south']
    
reg=re.compile(".*/.{4}_(\d{4})_(\d{4})_time-series_.*nc")

def get_file_and_year_range(exp, realm):
    """Return FILENAME, year start and year end of an experiment"""

    f = glob.glob(tsdir+'/'+exp+'/'+realm+'/'+exp+'_????_????_time-series_*.nc')

    # assume only one time series file
    if f:
        ma = reg.match(f[0])
        return ma.group(0), ma.group(1), ma.group(2)
    else:
        print('could not find a time series file for',exp,realm)
        

# --- Populate experiments

expa={}     # (file name, year start, year end) for atmosphere time series
expo={}     # (file name, year start, year end) for ocean time series
ds={}       # dataset

for e in args.exp:
    expa[e] = get_file_and_year_range(e,'atmosphere')
    expo[e] = get_file_and_year_range(e,'ocean')

    if expa[e] and expo[e]:
        ds[e] = xr.open_dataset(expa[e][0])
        ds[e] = xr.merge( [ds[e],
                           xr.open_dataset(expo[e][0])] )
        wanted =  atm_wanted + oce_wanted
    elif expa[e]:
        ds[e] = xr.open_dataset(expa[e][0])
        wanted =  atm_wanted
    elif expo[e]:
        ds[e] = xr.open_dataset(expo[e][0]).rename({'time_counter':'time'}, inplace=True)
        wanted = oce_wanted
    else:
        print(' No timeseries found.')
        sys.exit(1)

# --- Plot experiments

if pdf:
    ###########################################
    # All plots in one pdf, one plot per page #
    ###########################################
    if not args.fname:
        pdfname = args.exp[0] + '_timeseries.pdf'
    else:
        pdfname = args.fname
        
    with PdfPages(pdfname) as pdf:

        for k in wanted:
            plt.figure(figsize=(8,6))

            lines=[]
            for i,e in enumerate(args.exp):

                title = ds[e][k].attrs['long_name']
                if '_north' in k:
                    title=title+' (North)'
                if '_south' in k:
                    title=title+' (South)'
                units = ds[e][k].attrs['units']
                vtime = ( ds[e][k].coords.keys() & {'time_counter', 'time'} ).pop()
                print(title)
                if not args.ave: ds[e][k].plot(color='C'+str(i), linewidth=.7, linestyle="--")
                line,= ds[e][k].rolling(**{vtime:12, "center": True}).mean().dropna(vtime).plot(color='C'+str(i), label=labels[i])
                lines.append(line)
                axes = plt.gca()
                axes.grid()

            plt.ylabel(units)
            plt.title(title)
            plt.legend(lines, labels)
            #plt.xticks(range(1990,2011,2))

            pdf.savefig()
            plt.close()
else:        
    #####################################
    # Interactive: one at a time  plots #
    #####################################
    f = plt.figure(figsize=(10,8))
    plt.ion() # prevents that the execution stops after plotting
    plt.show()

    for k in wanted:
        plt.clf()
        lines=[]
        for i,e in enumerate(args.exp):
            
            title = ds[e][k].attrs['long_name']
            if '_north' in k:
                title=title+' (North)'
            if '_south' in k:
                title=title+' (South)'
            units = ds[e][k].attrs['units']
            vtime = ( ds[e][k].coords.keys() & {'time_counter', 'time'} ).pop()
            print(title)
            if not args.ave: ds[e][k].plot(color='C'+str(i), linewidth=.7, linestyle="--")
            line,= ds[e][k].rolling(**{vtime:12, "center": True}).mean().dropna(vtime).plot(color='C'+str(i), label=labels[i])
            lines.append(line)
            axes = plt.gca()
            axes.grid()
            
        plt.ylabel(units)
        plt.title(title)
        plt.legend(lines, labels)

        #plt.xticks(range(1990,2011,2))
        
        f.canvas.draw()
        what = input("Enter for Next")


