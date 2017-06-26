# L. Brodeau, november 2013

import sys
import os
import numpy as nmp
from netCDF4 import Dataset

# From BaraKuda python package:
import barakuda_orca as bo
import barakuda_plot as bp
import barakuda_tool as bt


cv_time  = 'time_counter'
cv_depth = 'gdept'

CRUN = os.getenv('RUN')
if CRUN == None: print 'The RUN environement variable is no set'; sys.exit(0)

SUPA_FILE = os.getenv('SUPA_FILE')
if SUPA_FILE == None: print 'The SUPA_FILE environement variable is no set'; sys.exit(0)

print '\n *** '+sys.argv[0]+' => USING time series in '+SUPA_FILE

bt.chck4f(SUPA_FILE)


# Reading all var in netcdf file:

id_clim = Dataset(SUPA_FILE)

list_variables = id_clim.variables.keys()

list_variables.remove(cv_time)

l3d = False
if cv_depth in list_variables:
    l3d = True
    list_variables.remove(cv_depth)


nbvar = len(list_variables)

nbvar_2d = 0
for cv2d in [ 'votemper' , 'vosaline' ]:
    if cv2d in list_variables: nbvar_2d = nbvar_2d + 1


nbvar_1d = nbvar - nbvar_2d



list_units = nmp.zeros(nbvar, dtype = nmp.dtype('a8'))
list_lngnm = nmp.zeros(nbvar, dtype = nmp.dtype('a64'))


vtime  = id_clim.variables[cv_time][:]   ; nbr   = len(vtime)




X1d = nmp.zeros(nbvar_1d*nbr)       ; X1d.shape = [nbvar_1d, nbr]

if l3d:
    vdepth = id_clim.variables[cv_depth][:]
    nblev  = len(vdepth)
    X2d    = nmp.zeros(nbvar_2d*nbr*nblev) ; X2d.shape = [nbvar_2d, nbr, nblev ]


jv1d = -1
jv2d = -1

for jv in range(nbvar):

    cv  = list_variables[jv]    
    
    print '\n **** reading '+cv

    XX = id_clim.variables[cv]
    shape_XX = nmp.shape(XX)
    ndim = len(shape_XX)
    print '      * dimension => '+str(ndim)+'D'
    
    if ndim == 1:
        jv1d = jv1d + 1
        X1d[jv1d,:]   = XX[:]
        
    elif ndim == 3 and shape_XX[1] == 1 and shape_XX[2] == 1 :
        jv1d = jv1d + 1
        X1d[jv1d,:]   = XX[:,0,0]
        
    elif  ndim == 2 and l3d:
        jv2d = jv2d + 1
        X2d[jv2d,:,:] = XX[:,:]
        
    else:
        print ' ERROR in '+sys.argv[0]+' => variable '+cv+' has a weird dimension!!! ', ndim
        sys.exit(0)
        
    list_units[jv] = id_clim.variables[cv].units
    list_lngnm[jv] = id_clim.variables[cv].long_name
    print '      * units    => '+list_units[jv]
    print '      * longname => '+list_lngnm[jv]




    cln = list_lngnm[jv]
    cfn  = cv+'_'+CRUN

    print '   Creating figure '+cfn


    # I) 
    # --------------------

    if cv[:12] == 'tot_area_ice':

        # Sea-Ice extent

        nby = nbr/12

        vice_c = nmp.zeros(nby*2) ; vice_c.shape = [2, nby]
        vt_y      = nmp.zeros(nby)

        for jy in range(nby):
            j03 = jy*12+2 ; j09 = jy*12+8
            vt_y[jy] = nmp.round(vtime[jy*12],0)+0.5
            vice_c[0,jy] = X1d[jv1d,j03]
            vice_c[1,jy] = X1d[jv1d,j09]


        ittic = bt.iaxe_tick(nby)
            
        bp.plot_1d_multi(vt_y, vice_c, vlabels=['March', 'September'], cfignm=cfn,
                         dt_year=ittic, cyunit=list_units[jv], ctitle = CRUN+': Sea-Ice extent ('+cv[13:]+')',
                         cfig_type='svg', l_tranparent_bg=False)



        
        
    elif cv == 'votemper' or cv == 'vosaline':

        if not l3d:
            print ' ERROR: '+sys.argv[0]+' => variable '+cv+' are here but '+cv_depth+' was not there!'
            sys.exit(0)


        VY, ZY = bt.monthly_2_annual(vtime, nmp.flipud(nmp.rot90(X2d[jv2d,:,:])))

        y1 = int(VY[0]) ;   y2 = int(VY[nbr/12-1])
        ittic = bt.iaxe_tick(nbr/12)
	
        # Anomaly with regards to first year:
        vini = nmp.zeros(nblev) ; vini[:] = ZY[:,0]
        for jy in range(nbr/12): ZY[:,jy] = ZY[:,jy] - vini[:]

        [ rmin, rmax, rdf ] = bt.get_min_max_df(ZY,40)

        bp.plot_vert_section(VY-0.5, vdepth[:], ZY, ZY*0.+1., rmin, rmax, rdf,
                             cpal='bbr2', xmin=y1, xmax=y2, dx=ittic, lkcont=True,
                             zmin = vdepth[0], zmax = max(vdepth), l_zlog=True,
                             cfignm=cfn, cbunit=r''+list_units[jv],
                             czunit='Depth (m)',
                             ctitle=CRUN+': '+cln,
                             cfig_type='svg', lforce_lim=True, i_sub_samp=2)

        


    else:

        # Normal variables!
        
    
        # Annual data
        VY, FY = bt.monthly_2_annual(vtime[:], X1d[jv1d,:])
    
        ittic = bt.iaxe_tick(nbr/12)
    
        # Time to plot
        bp.plot_1d_mon_ann(vtime[:], VY, X1d[jv1d,:], FY, cfignm=cfn, dt_year=ittic,
                           cyunit=list_units[jv], ctitle = CRUN+': '+cln,
                           cfig_type='svg', l_tranparent_bg=False)








id_clim.close()

print '   *** '+sys.argv[0]+' done!\n'



