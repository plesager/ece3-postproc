#!/usr/bin/env python3

DOC = """ Plot timeseries of monthly global averages (as computed by the
timeseries tool of ECE3_POST_PROC package) from one or more experiments.

!!! YOU MUST SET THE tsdir CONFIG IN THE SCRIPT !!!!

 When modifying the default labelling, and it is not followed by
 another option, you must use a double dash (--) before the
 experiment(s) name. For example, you can do something like this for
 multiple experiments:

   ./plot_timeseries.py --label '1st exp' 'another one' -- exp1 exp2

"""

import argparse
import os, sys, glob, re
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import numpy as np
import pandas as pd

# -- CONFIG: location of timeseries (same as ECE3_POSTPROC_DIAGDIR in your conf/<machine>/conf_timeseries_<machine>.sh)
tsdir='/nobackup_2/users/sager/DIAG/'

parser = argparse.ArgumentParser(description=DOC, formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument("exp", metavar='EXPi', nargs='+', help="id of each exp")
parser.add_argument('-l', "--label", nargs='+', help="overwrite default legend in plots")
parser.add_argument("-p", "--pdf", help="will put all plots in one pdf file", action="store_true")
parser.add_argument("-f", "--fname", help="file name for pdf output"+
                    "(default: exp1_timeseries.pdf)")
parser.add_argument("-t", "--title", help="main plot title (default: none)")
parser.add_argument("-a", "--ave", help="12-month moving average ONLY", action="store_true")
parser.add_argument("-b", "--bigave", help="yearly average", action="store_true") #EXPERIMENTAL - WIP
parser.add_argument("-m", "--marks", help="use markers in the moving average lines", action="store_true")
parser.add_argument("-y", "--years", help="year range", nargs=2, type=float)

args = parser.parse_args()
pdf = args.pdf
use_mark = args.marks
prepend = args.title +" - " if args.title else ''

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

atm_wanted=['str','tas', 'msl', 'e', 'totp', 'tcc', 'ssr', 'tsr',
            'PminE', 'NetTOA', 'NetSFCs', 'NetSFC' ]

oce_wanted = ['sosstsst', 'sosaline', 'sossheig', 'votemper_3d',
              'vosaline_3d', 'max_amoc_30N', 'max_amoc_40N',
              'max_amoc_50N', 'tot_area_ice_north', 'tot_area_ice_south']

#atm_wanted=['tas']
#oce_wanted = ['sossheig']


reg=re.compile(".*/.{4}_(\d{4})_(\d{4})_time-series_.*nc")

def get_file_and_year_range(exp, realm):
    """Return FILENAME, year start and year end of an experiment"""

    f = glob.glob(tsdir+'/'+exp+'/'+realm+'/'+exp+'_????_????_time-series_*.nc')
    f.sort()

    # assume only one time series file
    if f:
        ma = reg.match(f[-1])
        print( ma.group(0), ma.group(1), ma.group(2))
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

    if expa[e]:
        dsa = xr.open_dataset(expa[e][0])
        # Avoid panda time types by switching to fractional year
        # (Could be made optional - here to avoid issues when cdo has
        # been applied to the timeseries, or very long ones)
        dsa.coords['time'] = float(expa[e][1]) + (np.arange(len(dsa.time), dtype=float)+0.5)/12.

        # hack - time shift (could be made an option, applied only if using fractional year as time axis)
        if e == 't264':
            dsa.coords['time'] = float(expa[e][1])-310. + (np.arange(len(dsa.time), dtype=float)+0.5)/12.

        # create a year coordinates (needed when switching to
        # fractional year to be able to do yearly means, but you
        # cannot do rolling average)
        dsa.coords['year'] = (dsa['time'] // 1).astype('int')
        
    if expo[e]:
        dso = xr.open_dataset(expo[e][0]).rename({'time_counter':'time'})
        # switch to fractional year
        dso.coords['time'] = float(expo[e][1]) + (np.arange(len(dso.time), dtype=float)+0.5)/12.
        # shift time (could be made an option)
        if e == 't264':
            dso.coords['time'] = float(expo[e][1])-310. + (np.arange(len(dso.time), dtype=float)+0.5)/12.
        dso.coords['year'] = (dso['time'] // 1).astype('int')

    if expa[e] and expo[e]:
        ds[e] = xr.merge( [dsa, dso] )
        wanted =  atm_wanted + oce_wanted
    elif expa[e]:
        ds[e] = dsa
        wanted =  atm_wanted
    elif expo[e]:
        ds[e] = dso
        wanted = oce_wanted
    else:
        print(' No timeseries found.')
        sys.exit(2)

    print(' time axis for {} exp: from {} to {}'.format(e, ds[e].time.values[0], ds[e].time.values[-1]))


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

                try:
                    title = prepend + ds[e][k].attrs['long_name']
                except:
                    continue
                
                if '_north' in k:
                    title=title+' (North)'
                if '_south' in k:
                    title=title+' (South)'
                units = ds[e][k].attrs['units']
                vtime = ( ds[e][k].coords.keys() & {'time_counter', 'time'} ).pop()
                print(title)

                if 'area_ice' in k:
                    print("(scaling)")
    #                tempo = ds[e][k]
                    cond = ds[e][k] < 3.0e14
                    #print(cond)
                    #print(cond[0], ds[e][k][0])
                    #ds[e][k] = xr.where(cond, ds[e][k]*100., ds[e][k])
                    #print(cond[0], ds[e][k][0])

                # Yearly mean and 12-month moving average possible only if there are more than 12 months of data
                if len(ds[e][k]) > 12:
                    if args.bigave:
                        line,= ds[e][k].groupby('year').mean().plot(color='C'+str(i),
                                                                    label=labels[i],
                                                                    marker=m[i] if use_mark else '')
                    else:
                        if not args.ave: ds[e][k].plot(color='C'+str(i), linewidth=1, linestyle="--")
                        line,= ds[e][k].rolling(**{vtime:12, "center": True}).mean().plot(color='C'+str(i),
                                                                                          label=labels[i],
                                                                                          marker=m[i] if use_mark else '')
                    lines.append(line)
                else:
                    if not args.ave: ds[e][k].plot(color='C'+str(i), linewidth=1, label=labels[i])

            axes = plt.gca()
            axes.grid()

            plt.ylabel(units)
            plt.title(title)
            if args.years: plt.xlim(args.years)
            if lines:
                plt.legend(lines, labels)
            else:
                plt.legend(labels)


#            # indicates where the Initial States are picked up
#            ylim = axes.get_ylim()
#            selected_dates = list(range(2080, 2150, 40))
#            axes.vlines(selected_dates, ylim[0], ylim[1], linewidths=0.6, color='r')
#            for member in selected_dates:
#                axes.text(member, ylim[0], str(selected_dates.index(member)+1), color='r',
#                          verticalalignment='top', horizontalalignment='center', fontweight='bold')

            # selected_dates = list(range(2280, 2720, 40))
            # axes.vlines(selected_dates, ylim[0], ylim[1], linewidths=0.6, color='r')
            # for member in selected_dates:
            #     axes.text(member, ylim[0], str(selected_dates.index(member)+14), color='r',
            #               verticalalignment='top', horizontalalignment='center', fontweight='bold')

            # plt.xticks(range(2160,2670,100))

            pdf.savefig()
            plt.close()
else:
    #####################################
    # Interactive: one at a time  plots #
    #####################################
    f = plt.figure(figsize=(10,8))
    plt.ion() # prevents that the execution stops after plotting
    plt.show()

    m=['^','v','^','v']

    for k in wanted:
        plt.clf()
        lines=[]
        for i,e in enumerate(args.exp):

            try:
                title = prepend + ds[e][k].attrs['long_name']
            except:
                continue
            
            if '_north' in k:
                title = title+' (North)'
            if '_south' in k:
                title = title+' (South)'
            units = ds[e][k].attrs['units']
            vtime = ( ds[e][k].coords.keys() & {'time_counter', 'time'} ).pop()
            #print(ds[e].coords['time'])
            print(title)

            if 'area_ice' in k:
                print("(scaling)")
#                tempo = ds[e][k]
                cond = ds[e][k] < 3.0e14
                #print(cond)
                #print(cond[0], ds[e][k][0])
                ds[e][k] = xr.where(cond, ds[e][k]*100., ds[e][k])
                #print(cond[0], ds[e][k][0])

            # Yearly mean and 12-month moving average possible only if there are more than 12 months of data
            if len(ds[e][k]) > 12:
                if args.bigave:
                    line,= ds[e][k].groupby('year').mean().plot(color='C'+str(i),
                                                                label=labels[i],
                                                                marker=m[i] if use_mark else '')
                else:
                    if not args.ave: ds[e][k].plot(color='C'+str(i), linewidth=1, linestyle="--")
                    line,= ds[e][k].rolling(**{vtime:12, "center": True}).mean().plot(color='C'+str(i),
                                                                                      label=labels[i],
                                                                                      marker=m[i] if use_mark else '')
                lines.append(line)
            else:
                if not args.ave: ds[e][k].plot(color='C'+str(i), linewidth=1, label=labels[i])

        axes = plt.gca()
        axes.grid()

        plt.ylabel(units)
        plt.title(title)
        if args.years: plt.xlim(args.years)
        if lines:
            plt.legend(lines, labels)
        else:
            plt.legend(labels)

#        # indicates where the Initial States are picked up
#        ylim = axes.get_ylim()
#        selected_dates = list(range(2000, 2150, 10))
#        axes.vlines(selected_dates, ylim[0], ylim[1], linewidths=0.6, color='r')
#        for member in selected_dates:
#            axes.text(member, ylim[0], str(selected_dates.index(member)+1), color='r',
#                      verticalalignment='top', horizontalalignment='center', fontweight='bold')

        # selected_dates = list(range(2280, 2722, 40))
        # axes.vlines(selected_dates, ylim[0], ylim[1], linewidths=0.6, color='r')
        # for member in selected_dates:
        #     axes.text(member, ylim[0], str(selected_dates.index(member)+14), color='r',
        #               verticalalignment='top', horizontalalignment='center', fontweight='bold')

        # plt.xticks(range(2160, 2670, 100))

        # adhoc
        # ylim = axes.get_ylim()
        # delta = ylim[1] - ylim[0]
        # axes.vlines('1951', ylim[0]+0.1*delta, ylim[0]+0.3*delta, linewidths=1.6, color='r')
        # axes.vlines('1954', ylim[0]+0.6*delta, ylim[0]+0.8*delta, linewidths=1.6, color='r')

        f.canvas.draw()
        what = input("Enter for Next")

