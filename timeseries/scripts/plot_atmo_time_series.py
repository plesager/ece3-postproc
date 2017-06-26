# L. Brodeau, november 2013

import sys
import os
import numpy as nmp
from netCDF4 import Dataset

# From BaraKuda python package:
import barakuda_orca as bo
import barakuda_plot as bp
import barakuda_tool as bt


CRUN = os.getenv('RUN')
if CRUN == None: print 'The RUN environement variable is no set'; sys.exit(0)

SUPA_FILE = os.getenv('SUPA_FILE')
if SUPA_FILE == None: print 'The SUPA_FILE environement variable is no set'; sys.exit(0)





#narg = len(sys.argv)
#if narg != 2: print 'Usage: '+sys.argv[0]+' <diag>'; sys.exit(0)
#cdiag = sys.argv[1]
#print '\n plot_time_series.py: diag => "'+cdiag+'"'






v_var_names = [ 'msl', 'tas', 'totp', 'NetTOA', 'NetSFC', 'PminE', 'e', 'tcc', 'PminE', 'tsr', 'ssr' ]
nbvar = len(v_var_names)

v_var_units = nmp.zeros(nbvar, dtype = nmp.dtype('a8'))
v_var_lngnm = nmp.zeros(nbvar, dtype = nmp.dtype('a64'))


print '\n *** plot_atmo_time_series.py => USING time series in '+SUPA_FILE


bt.chck4f(SUPA_FILE)


# Reading all var in netcdf file:

id_clim = Dataset(SUPA_FILE)

vtime = id_clim.variables['time'][:]

nbr   = len(vtime)

XX = nmp.zeros(nbvar*nbr) ; XX.shape = [nbvar, nbr]

for jv in range(nbvar):
    print ' **** reading '+v_var_names[jv]
    XX[jv,:] = id_clim.variables[v_var_names[jv]][:]
    #TODO add check for non-existent units & long_name
    v_var_units[jv] = id_clim.variables[v_var_names[jv]].units
    v_var_lngnm[jv] = id_clim.variables[v_var_names[jv]].long_name

id_clim.close()




for jv in range(nbvar):

    cv  = v_var_names[jv]
    cln = v_var_lngnm[jv]
    cfn  = cv+'_'+CRUN

    print '   Creating figure '+cfn

    # Annual data
    VY, FY = bt.monthly_2_annual(vtime[:], XX[jv,:])

    ittic = bt.iaxe_tick(nbr/12)

    # Time to plot
    bp.plot_1d_mon_ann(vtime[:], VY, XX[jv,:], FY, cfignm=cfn, dt_year=ittic,
                          cyunit=v_var_units[jv], ctitle = CRUN+': '+cln,
                          cfig_type='svg', l_tranparent_bg=False)













sys.exit(0)














if   cdiag == '3d_thetao':
    fig_id = 'ts3d'
    clnm = 'Globally-averaged temperature'
    cyu  = r'($^{\circ}$C)'
    #ym = 3.6 ; yp = 4.
    ym = 0. ; yp = 0.
    #ym0  = 1.5 ; yp0 = 20.
    ym0  = 0. ; yp0 = 0.    

elif cdiag == 'mean_tos':
    fig_id = 'simple'
    clnm = 'Globally-averaged sea surface temperature'
    cyu  = r'($^{\circ}$C)'
    ym = 0. ; yp = 0.
    
elif cdiag == '3d_so':
    fig_id = 'ts3d'
    clnm = 'Globally-averaged salinity'
    cyu  = r'(PSU)'
    #ym  = 34.6 ; yp  = 35.
    #ym0 = 34.6 ; yp0 = 35.
    ym  = 0. ; yp  = 0.
    ym0 = 0. ; yp0 = 0.
elif cdiag == 'mean_sos':
    fig_id = 'simple'
    clnm = 'Globally-averaged sea surface salinity'
    cyu  = r'(PSU)'
    ym = 0. ; yp = 0.

elif cdiag == 'mean_zos':
    fig_id = 'simple'
    clnm = 'Globally-averaged sea surface height'
    cyu  = r'(m)'
    ym = 0. ; yp = 0.

elif cdiag == 'amoc':
    fig_id = 'amoc'
    cyu  = r'(Sv)'
    ym = 3.75 ; yp = 20.25

elif cdiag == 'mean_mldr10_1':
    fig_id = 'mld'
    clnm   = 'Mean mixed-layer depth, '
    cyu    = r'(m)'
    ym = 0. ; yp = 0.


elif cdiag == 'transport_sections':
    fig_id = 'transport'    
    TRANSPORT_SECTION_FILE = os.getenv('TRANSPORT_SECTION_FILE')
    if TRANSPORT_SECTION_FILE == None: print 'The TRANSPORT_SECTION_FILE environement variable is no set'; sys.exit(0)    
    print '  Using TRANSPORT_SECTION_FILE = '+TRANSPORT_SECTION_FILE
    list_sections = bo.get_sections_names_from_file(TRANSPORT_SECTION_FILE)
    print 'List of sections to treat: ', list_sections



elif cdiag == 'seaice':
    fig_id = 'ice'
    cyu  = r'(10$^6$km$^2$)'



else:
    print 'ERROR: plot_time_series.py => diagnostic '+cdiag+' unknown!'; sys.exit(0)









##########################################
# Basic temp., sali. and SSH time series #
##########################################

if fig_id == 'simple':

    SUPA_FILE_m = cdiag+'_'+CRUN+'_global.dat'

    # Yearly data:
    #XY = bt.read_ascii_column(SUPA_FILE_y, [0, 1]) ; [ n0, nby ] = XY.shape

    # Monthly data:
    XM = bt.read_ascii_column(SUPA_FILE_m, [0, 1]) ; [ n0, nbm ] = XM.shape
    if nbm%12 != 0: print 'ERROR: plot_time_series.py => '+cdiag+', numberof records not a multiple of 12!', sys.exit(0)

    # Annual data
    VY, FY = bt.monthly_2_annual(XM[0,:], XM[1,:])

    ittic = bt.iaxe_tick(nbm/12)

    # Time to plot
    bp.plot_1d_mon_ann(XM[0,:], VY, XM[1,:], FY, cfignm=cdiag+'_'+CRUN, dt_year=ittic,
                         cyunit=cyu, ctitle = CRUN+': '+clnm, ymin=ym, ymax=yp)







if fig_id == 'ts3d':

    nb_oce = len(bo.voce2treat)

    joce = 0
    for coce in bo.voce2treat[:]:

        SUPA_FILE_m = cdiag+'_'+CRUN+'_'+coce+'.dat'
        
        # Monthly data:
        XM = bt.read_ascii_column(SUPA_FILE_m, [0, 1, 2, 3, 4]) # has 3 depth range!
        if joce == 0:
            [ n0, nbm ] = XM.shape
            if nbm%12 != 0: print 'ERROR: plot_time_series.py => '+cdiag+', numberof records not a multiple of 12!', sys.exit(0)
            FM = nmp.zeros(nbm*4*nb_oce) ; FM.shape = [ nb_oce, 4, nbm ]
        FM[joce,:,:] = XM[1:,:]

        # Annual data:
        if joce == 0:
            nby = nbm/12            
            FY = nmp.zeros(nby*4*nb_oce) ; FY.shape = [ nb_oce, 4, nby ]
        VY, FY[joce,:,:] = bt.monthly_2_annual(XM[0,:], FM[joce,:,:])

        joce = joce + 1

    ittic = bt.iaxe_tick(nby)
        
    # One plot only for global:
    bp.plot_1d_mon_ann(XM[0,:], VY, FM[0,0,:], FY[0,0,:], cfignm=cdiag+'_'+CRUN, dt_year=ittic,
                         cyunit=cyu, ctitle = CRUN+': '+clnm, ymin=ym, ymax=yp)

    
    # Global for different depth:    
    vlab = [ 'All', '0m-100m', '100-1000m', '1000m-bottom' ]
    bp.plot_1d_multi(XM[0,:], XM[1:,:], vlab, cfignm=cdiag+'_lev_'+CRUN, dt_year=ittic,
                       cyunit=cyu, ctitle = CRUN+': '+clnm, ymin=ym0, ymax=yp0)


    # Show each ocean (All depth):
    bp.plot_1d_multi(XM[0,:], FM[:,0,:], bo.voce2treat, cfignm=cdiag+'_basins_'+CRUN, dt_year=ittic,
                       cyunit=cyu, ctitle = CRUN+': '+clnm, ymin=ym0, ymax=yp0)



##########################################
# AMOC
##########################################

if fig_id == 'amoc':

    SUPA_FILE_m = cdiag+'_'+CRUN+'.dat'

    # Position of columns of AMOC / latitude in the ASCII file:
    ic20 =  1
    ic30 =  4
    ic40 =  7
    ic45 = 10
    ic50 = 13

    # 45N:
    XM = bt.read_ascii_column(SUPA_FILE_m, [0, ic45]) ; [ n0, nbm ] = XM.shape
    if nbm%12 != 0: print 'ERROR: plot_time_series.py => '+cdiag+', numberof records not a multiple of 12!', sys.exit(0)
    VY, FY = bt.monthly_2_annual(XM[0,:], XM[1,:])

    ittic = bt.iaxe_tick(nbm/12)

    # Time to plot
    bp.plot_1d_mon_ann(XM[0,:], VY, XM[1,:], FY, cfignm=cdiag+'_'+CRUN, dt_year=ittic,
                         cyunit=cyu, ctitle = CRUN+': '+r'Max. of AMOC at 45$^{\circ}$N', ymin=ym, ymax=yp, dy=1.)


    # 20, 30, 40, 50N

    vlab = [ r'20$^{\circ}$N' , r'30$^{\circ}$N' , r'40$^{\circ}$N' , r'50$^{\circ}$N' ]
    
    XM = bt.read_ascii_column(SUPA_FILE_m, [0, ic20, ic30, ic40, ic50]) ; [ n0, nbm ] = XM.shape
    if nbm%12 != 0: print 'ERROR: plot_time_series.py => '+cdiag+', numberof records not a multiple of 12!', sys.exit(0)

    # Annual:
    VY, FY  = bt.monthly_2_annual(XM[0,:], XM[1:,:])

    # Time to plot
    bp.plot_1d_multi(VY, FY, vlab, cfignm=cdiag+'_'+CRUN+'_comp', dt_year=ittic,
                         cyunit=cyu, ctitle = CRUN+': '+r'Max. of AMOC', ymin=0, ymax=0)







if fig_id == 'ice':
    
    vlab = [ 'Arctic', 'Antarctic' ]
    SUPA_FILE = cdiag+'_'+CRUN+'.dat'

    # montly sea-ice volume and extent, Arctic and Antarctic...
    Xice = bt.read_ascii_column(SUPA_FILE, [0, 1, 2, 3, 4])

    [ n0, nbm ] = Xice.shape
    if nbm%12 != 0: print 'ERROR: plot_time_series.py => '+cdiag+', numberof records not a multiple of 12!', sys.exit(0)
    nby = nbm/12
    
    ittic = bt.iaxe_tick(nby)

    vtime_y = nmp.zeros(nby)
    Xplt = nmp.zeros(2*nby) ; Xplt.shape = [2 , nby]

    vtime_y[:]  = nmp.trunc(Xice[0,2::12]) + 0.5
    
    # End local summer
    Xplt[0,:] = Xice[2,8::12] ; # extent Arctic september
    Xplt[1,:] = Xice[4,2::12] ; # extent Antarctic march

    bp.plot_1d_multi(vtime_y, Xplt, vlab, cfignm='seaice_summer_'+CRUN, dt_year=ittic,
                        cyunit=cyu, ctitle = CRUN+': '+r'Sea-Ice extent, end of local summer', ymin=0., ymax=0.)

    # Extent: end of local winter
    Xplt[0,:] = Xice[2,2::12] ; # extent Arctic march
    Xplt[1,:] = Xice[4,8::12] ; # extent Antarctic september
    bp.plot_1d_multi(vtime_y, Xplt, vlab, cfignm='seaice_winter_'+CRUN, dt_year=ittic,
                       cyunit=cyu, ctitle = CRUN+': '+r'Sea-Ice extent, end of local winter', ymin=0., ymax=0.)

    


if fig_id == 'transport':

    for csec in list_sections:

        print ' * treating section '+csec

        SUPA_FILE_m = 'transport_sections/transport_'+csec+'_'+CRUN+'.dat'

        XM = bt.read_ascii_column(SUPA_FILE_m, [0, 1, 2]) ; [ n0, nbm ] = XM.shape
        if nbm%12 != 0: print 'ERROR: plot_time_series.py => '+cdiag+', numberof records not a multiple of 12!', sys.exit(0)

        VY, FY  = bt.monthly_2_annual(XM[0,:], XM[1:,:])        

        ittic = bt.iaxe_tick(nbm/12)

        # Transport of mass:
        bp.plot_1d_mon_ann(XM[0,:], VY, XM[1,:], FY[0,:], cfignm='transport_vol_'+csec+'_'+CRUN,
                             dt_year=ittic, cyunit='(Sv)', ctitle = CRUN+': transport of volume, '+csec,
                             ymin=0, ymax=0)

        # Transport of heat:
        bp.plot_1d_mon_ann(XM[0,:], VY, XM[2,:], FY[1,:], cfignm='transport_heat_'+csec+'_'+CRUN,
                             dt_year=ittic, cyunit='(PW)', ctitle = CRUN+': transport of heat, '+csec,
                             ymin=0, ymax=0, mnth_col='g')




if fig_id == 'mld':
    jbox = 0
    for cbox in bo.cname_mld_boxes:
        SUPA_FILE_m = cdiag+'_'+CRUN+'_'+cbox+'.dat'
        if os.path.exists(SUPA_FILE_m):
            print ' Opening '+SUPA_FILE_m
            XM = bt.read_ascii_column(SUPA_FILE_m, [0, 1]) ; [ n0, nbm ] = XM.shape ; # Monthly data:
            if nbm%12 != 0: print 'ERROR: plot_time_series.py => '+cdiag+', numberof records not a multiple of 12!', sys.exit(0)
            VY, FY = bt.monthly_2_annual(XM[0,:], XM[1,:]) ; # Annual data
            ittic = bt.iaxe_tick(nbm/12)
            bp.plot_1d_mon_ann(XM[0,:], VY, XM[1,:], FY, cfignm=cdiag+'_'+CRUN+'_'+cbox, dt_year=ittic, cyunit=cyu,
                                  ctitle = CRUN+': '+clnm+bo.clgnm_mld_boxes[jbox], ymin=ym, ymax=yp, plt_m03=True, plt_m09=True)
        else:
            print 'WARNING: plot_time_series.py => MLD diag => '+SUPA_FILE_m+' not found!'
        jbox = jbox+1


print 'plot_time_series.py done...\n'
