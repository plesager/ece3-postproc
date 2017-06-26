
import sys
import numpy as nmp

import matplotlib as mpl
mpl.use('Agg') ; # important so no DISPLAY is needed!!!
import matplotlib.pyplot as plt
import matplotlib.colors as colors

from math import trunc

# Mine:
import barakuda_orca as brkdo


# Old savefig option:
# savefig(cfignm+'.'+cfig_type, dpi=100, facecolor='w', edgecolor='w', orientation='portrait'


# Time-series:
WDTH_TS     = 13.2
FIG_SIZE_TS = (WDTH_TS,4.2)
DPI_TS      = 120
AXES_TS     = [0.08, 0.05, 0.89, 0.89]





# For projections :
# =================
# lcc = Lambert conformal conic
#
# my zone PROJ llcrnrlon llcrnrlat urcrnrlon urcrnrlat   lat1  lon0 mer/par continent-res
projection_def = [
         ['nseas',   'lcc',  -55., 40., 55., 75.,           60., -20., 10., 'l' ],   # Nordic seas
         ['natarct', 'lcc', -65., 35., 80., 60.,           50., -32., 10., 'l' ],   # NATL + Arctic
         ['labir',   'lcc',  -62., 48., -10., 75.,          50., -30.,  5., 'l' ],
         ['labsp',   'lcc',  -60., 48., 50., 75.5,          50., -30., 10., 'l' ],
         ['npol',    'stere', -75., 45., 100., 60.,          80., -30., 10., 'l' ],
         ['npol2',   'stere', -55., 40., 145., 40.,          80.,  -5., 10., 'l' ],   # North Pole
         ['spstere', 'stere',  0.,  0.,  0., 0.,            -48.,  90., 10., 'l' ],   # South Pole Default matplotlib!
         ['matl' ,   'cyl',  -82.,-21.,  12., 79.,          30., -30., 15., 'l' ],   # Nordic seas
         ['atmed',   'lcc',  -18., 33.,  -2., 42.,          30., -10.,  5., 'h' ],
         ['kav7' ,   'kav',    0.,  0.,   0.,  0.,           0.,   0.,  0., 'l' ] ] # global map-monde
         
#
#         ['spol2',   'stere', -45.,-35., 130., -35.,        -88.,   5., 10., 'l' ],   # South Pole
#         ['spol2','stere', -45.,-38., 130.,-35.,         -90.,  -5., 10., 'l' ],   # South Pole

#=================================================================================
#          ['natarct','lcc', -65., 35., 88., 70.,     50., -30., 10., 'h' ],   # NATL + Arctic














    
def plot_vert_section(VX, VZ, XF, XMSK, rmin, rmax, dc, lkcont=True, cpal='jet', xmin=-80., xmax=85., dx=5,
               cfignm='fig', cbunit='', cxunit=' ', zmin = 0., zmax = 5000., l_zlog=False,
               cfig_type='pdf', czunit=' ', ctitle=' ', lforce_lim=False, i_sub_samp=1, l_z_increase=False ):
    
    import math
    import barakuda_colmap

    font_ttl, font_ylb, font_clb = __font_unity__()
    
    zVZ = nmp.zeros(len(VZ)) ; zVZ.shape = [ len(VZ) ]

    # If log / z:
    if l_zlog:
        zmin = math.log10(zmin); zmax = math.log10(zmax);
        for jk in range(len(VZ)): zVZ[jk] = math.log10(VZ[jk])
    else:
        zVZ= VZ


    if lforce_lim: __force_min_and_max__(rmin, rmax, XF)

    # Masking where mask is zero!
    XF = nmp.ma.masked_where(XMSK == 0, XF)


    fig = plt.figure(num = 1, figsize=(WDTH_TS,5.), dpi=None, facecolor='w', edgecolor='k')
    ax = plt.axes([0.06,  0.1,   1.02,       0.82], axisbg = 'gray')
    vc = __vcontour__(rmin, rmax, dc); #print 'plot_vert_section: contours =>\n', vc, '\n'

    # Palette:
    palette = barakuda_colmap.chose_palette(cpal)
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)

    cf = plt.contourf(VX, zVZ, XF, vc, cmap = palette, norm = pal_norm)
    plt.hold(True)
    if lkcont: plt.contour(VX, zVZ, XF, vc, colors='k', linewidths=0.2)



    # Colorbar
    clb = plt.colorbar(cf, ticks=vc); clb.set_label('('+cbunit+')', **font_clb)
    # Sub-sampling if needed:
    if i_sub_samp != 1:
        cb_labels = [] ; cpt = i_sub_samp
        for cr in vc:
            rr = round(float(cr),6) ; cnr = str(rr)
            if cpt == i_sub_samp:
                cpt = 1 ; cb_labels.append(cnr)
            else:
                cpt = cpt + 1 ; cb_labels.append(' ')
        clb.ax.set_yticklabels(cb_labels)

    for t in clb.ax.get_yticklabels(): t.set_fontsize(10)


    # X-axis:
    plt.xticks( nmp.arange(xmin, xmax+dx, dx) )
    plt.xlabel(cxunit, **font_ylb); 

    # Y-axis:
    plt.ylabel(czunit, **font_ylb)
    # Correcting ticks for log
    if l_zlog:
        locs, labels = plt.yticks(); cny = []
        print 'locs =', locs
        for jl in range(len(locs[:])): cny.append(str(int(10**locs[jl])))
        plt.yticks(locs,cny)


    # Y-X limits:
    if l_z_increase:
        plt.axis([xmin, xmax, zmin, zmax])
    else:
        plt.axis([xmin, xmax, zmax, zmin])

    # Prevents from using scientific notations in axess ticks numbering:
    ax.get_xaxis().get_major_formatter().set_useOffset(False)

    plt.title(ctitle, **font_ttl)
    plt.savefig(cfignm+'.'+cfig_type, dpi=DPI_TS, orientation='portrait', transparent=False)
    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)

    return






































def plot_2d(VX, VY, XF, XMSK, rmin, rmax, dc, corca='ORCA1', lkcont=True, cpal='jet',
            cfignm='fig', cbunit='', ctitle=' ', lforce_lim=False, i_sub_samp=1,
            cfig_type='pdf', lat_min=-75., lat_max=75., lpix=False, vcont_spec = []):

    #
    # Plot nicely a field given on ORCA coordinates on 2D world map without using any projection
    #
    
    import barakuda_tool  as brkdt    
    import barakuda_colmap as brkdcm


    font_ttl, font_ylb, font_clb = __font_unity__()

    # Don't want to modify XF array, working with XFtmp:
    [ny, nx] = nmp.shape(XF)
    XFtmp = nmp.zeros(ny*nx) ; XFtmp.shape = [ny, nx]
    XFtmp[:,:] = XF[:,:]


    # First drowning the field:
    brkdt.drown(XFtmp, XMSK, k_ew=2, nb_max_inc=20, nb_smooth=10)



    rlon_ext = 32.

    if lforce_lim: __force_min_and_max__(rmin, rmax, XFtmp)

    VX0   = brkdo.lon_reorg_orca(VX,  corca, rlon_ext)
    iwa   = nmp.where(VX0 < 0.) ; VX0[iwa] = VX0[iwa] + 360.
    XMSK0 = brkdo.lon_reorg_orca(XMSK,corca, rlon_ext)
    XF0   = brkdo.lon_reorg_orca(XFtmp,  corca, rlon_ext)


    # Masking continents: => done later a cleaner way...
    #XF0 = nmp.ma.masked_where(XMSK0[:,:] < 0.5, XF0)


    vert_rat = (lat_max - lat_min)/(75. + 75.)


    # FIGURE
    # ~~~~~~
    fig = plt.figure(num = 1, figsize=(12.4,5.6*vert_rat), dpi=None, facecolor='w', edgecolor='k')
    ax = plt.axes([0.05, 0.06, 1., 0.86], axisbg = 'white')

    vc = __vcontour__(rmin, rmax, dc); #print vc, '\n'

    # Palette:
    palette = brkdcm.chose_palette(cpal)    
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)


    if lpix:
        # Pixelized plot:
        cf = plt.pcolor(VX0, VY, XF0, cmap = palette, norm = pal_norm)

    else:
        # Contour fill plot:
        cf = plt.contourf(VX0, VY, XF0, vc, cmap = palette, norm = pal_norm)
        for c in cf.collections: c.set_zorder(0.15)

        if lkcont:
            cfk = plt.contour(VX0, VY, XF0, vc, colors='k', linewidths = 0.2)
            for c in cfk.collections: c.set_zorder(0.25)

        # contour for specific values on the ploted field:
        if len(vcont_spec) >= 1:
            cfs = plt.contour(VX0, VY, XF0, vcont_spec, colors='white', linewidths = 1.2)
            plt.clabel(cfs, inline=1, fmt='%4.1f', fontsize=10)
            for c in cfs.collections: c.set_zorder(0.35)

        # Contours of continents:
        #cfm = plt.contour(VX0, VY, XMSK0, [ 0.7 ], colors='k', linewidths = 0.4)
        #for c in cfm.collections: c.set_zorder(1.)



    # Putting land-sea mask on top of current plot, cleaner than initial masking...
    # because won't influence contours since they are done
    # field needs to be DROWNED prior to this though!!!
    idx_land = nmp.where(XMSK0[:,:] < 0.5)
    XF0 = nmp.ma.masked_where(XMSK0[:,:] > 0.5, XF0)
    XF0[idx_land] = 1000.
    cf0 = plt.pcolor(VX0, VY, XF0, cmap = brkdcm.chose_palette('mask'))


    # Colorbar:
    # ~~~~~~~~
    clb = plt.colorbar(cf, ticks=vc, drawedges=lkcont); clb.set_label('('+cbunit+')', **font_clb)

    # Sub-sampling if needed:
    if i_sub_samp != 1:
        cb_labels = [] ; cpt = i_sub_samp
        for cr in vc:
            rr = round(float(cr),6) ; cnr = str(rr)
            if cpt == i_sub_samp:
                cpt = 1 ; cb_labels.append(cnr)
            else:
                cpt = cpt + 1 ; cb_labels.append(' ')
            clb.ax.set_yticklabels(cb_labels)

    # Decreasing font size
    ifsize = int(10*vert_rat); ifsize=max(ifsize,6)
    for t in clb.ax.get_yticklabels(): t.set_fontsize(ifsize)    


    # X and Y nice ticks:
    # ~~~~~~~~~~~~~~~~~~~
    [vvx, vvy, clon, clat] = __name_coor_ticks__(lon_ext=rlon_ext);
    plt.yticks(vvy,clat) ; plt.xticks(vvx,clon)

    plt.axis([ 0., 360.+rlon_ext-2., lat_min, lat_max])

    plt.title(ctitle, **font_ttl)

    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)

    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)

    del XFtmp, XF0

    return











def plot_2d_reg(VX, VY, XF, XMSK, rmin, rmax, dc, lkcont=False, cpal='jet',
               cfignm='fig', cfig_type='pdf', cbunit=' ', ctitle=' ',
               lforce_lim=False, cb_orient='vertical',
               lat_min=-77., lat_max=77., i_colorbar_jump=1, l_continent_pixel=True):


    import barakuda_tool   as brkdt    
    import barakuda_colmap as brkdcm


    font_ttl, font_ylb, font_clb = __font_unity__()


    # Don't want to modify XF array, working with XFtmp:
    [ny, nx] = nmp.shape(XF)
    XFtmp = nmp.zeros(ny*nx) ; XFtmp.shape = [ny, nx]
    XFtmp[:,:] = XF[:,:]

    # First drowning the field:
    brkdt.drown(XFtmp, XMSK, k_ew=0, nb_max_inc=20, nb_smooth=10)


    iext = 32

    if lforce_lim: __force_min_and_max__(rmin, rmax, XFtmp)

    # Extending / longitude:
    VXe = brkdt.extend_domain(VX,iext) ; XFe = brkdt.extend_domain(XFtmp,iext) ; XMSKe = brkdt.extend_domain(XMSK,iext)


    # FIGURE

    rat_vert = 1. / ( ( 77. + 77. ) / ( lat_max - lat_min ) )


    if cb_orient == 'horizontal':
        fig = plt.figure(num = 1, figsize=(12.4,6.6*rat_vert), dpi=None, facecolor='w', edgecolor='k')        
        ax = plt.axes([0.04, -0.01, 0.93, 0.96], axisbg = 'white')
    else:
        fig = plt.figure(num = 1, figsize=(12.4,5.6*rat_vert), dpi=None, facecolor='w', edgecolor='k')        
        ax = plt.axes([0.05, 0.06, 1.02, 0.88], axisbg = 'white')

    vc = __vcontour__(rmin, rmax, dc)

    # Palette:
    palette = brkdcm.chose_palette(cpal)
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)
    mpl.rcParams['contour.negative_linestyle'] = 'solid'
    plt.contour.negative_linestyle='solid'

    cf = plt.contourf(VXe, VY, XFe, vc, cmap = palette, norm = pal_norm)
    for c in cf.collections: c.set_zorder(0.15)
    #cf = pcolormesh(VXe, VY, XFe, cmap = palette, norm = pal_norm)

    if lkcont:
        cfk = plt.contour(VXe, VY, XFe, vc, colors='k', linewidths = 0.2)
        for c in cfk.collections: c.set_zorder(0.25)




    # Putting land-sea mask on top of current plot, cleaner than initial masking...
    # because won't influence contours since they are done
    # field needs to be DROWNED prior to this though!!!

    if l_continent_pixel:
        idx_land = nmp.where(XMSKe[:,:] < 0.5)
        XFe = nmp.ma.masked_where(XMSKe[:,:] > 0.5, XFe)
        XFe[idx_land] = 1000.
        cf0 = plt.pcolor(VXe, VY, XFe, cmap = brkdcm.chose_palette('mask'))
    else:
        #print 'poo'
        # Masking with contour rather than pixel:
        cf0 = plt.contourf(VXe, VY, XMSKe, [ 0., 0.1 ], cmap = brkdcm.chose_palette('mask'))
        # for c in cf0.collections: c.set_zorder(0.95)
        plt.contour(VXe, VY, XMSKe, [ 0. ], colors='k', linewidths = 1.)


    # COLOR BAR
    if cb_orient == 'horizontal':
        clb = plt.colorbar(cf, ticks=vc, drawedges=lkcont, orientation='horizontal', pad=0.07, shrink=1., aspect=40)
        for t in clb.ax.get_yticklabels(): t.set_fontsize(4)
        if i_colorbar_jump > 1:
            cn_clb = [] ; jcpt = 0
            for rtck in vc:
                if jcpt % i_colorbar_jump == 0:                
                    if float(int(rtck)) == round(rtck,0):
                        cn_clb.append(str(int(rtck))) ; # we can drop the ".0"
                    else:
                        cn_clb.append(str(rtck)) ; # keeping the decimals...
                else:
                    cn_clb.append(' ')
                jcpt = jcpt + 1
            clb.ax.set_xticklabels(cn_clb)
        for t in clb.ax.get_xticklabels(): t.set_fontsize(11) # Font size for colorbar ticks!
        clb.set_label('('+cbunit+')', **font_clb)
    else:
        clb = plt.colorbar(cf, ticks=vc, drawedges=lkcont, pad=0.03)
        clb.set_label('('+cbunit+')', **font_clb)
        for t in clb.ax.get_yticklabels(): t.set_fontsize(11) # Font size for colorbar ticks!

    # X and Y nice ticks:
    [vvx, vvy, clon, clat] = __name_coor_ticks__(lon_ext=iext);
    plt.yticks(vvy,clat) ; plt.xticks(vvx,clon)

    plt.axis([ 0., 360.+iext-2., lat_min, lat_max])


    if ctitle != ' ': plt.title(ctitle, **font_ttl)

    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)

    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)

    return

















def plot_2d_box(XF, XMSK, rmin, rmax, dc, lkcont=True,
                cpal='jet', cfignm='fig', cbunit='', ctitle=' ', lforce_lim=False,
                i_sub_samp=1, cfig_type='pdf', lcontours=True,
                x_offset=0., y_offset=0., vcont_spec = [], lcont_mask=False):

    import numpy as nmp
    import barakuda_colmap


    
    if lforce_lim: __force_min_and_max__(rmin, rmax, XF)

    [ ny , nx ] = XF.shape
    vert_rat = float(ny)/float(nx)
    print "Vert. ratio, nx, ny =", vert_rat, nx, ny

    # Masking field:
    if lcontours:
        idxm = nmp.where(XMSK[:,:] == 0); XF[idxm] = -9999.9  # c'est NaN qui merde!!!
    else:
        XF = nmp.ma.masked_where(XMSK == 0, XF)


    font_ttl, font_ylb, font_clb = __font_unity__()

    
    # FIGURE
    # ~~~~~~
    fig = plt.figure(num = 1, figsize=(7.,6.*vert_rat), dpi=None, facecolor='w', edgecolor='k')

    ax = plt.axes([0.07, 0.05, 0.9, 0.9], axisbg = 'gray')

    vc = __vcontour__(rmin, rmax, dc); #print vc, '\n'

    # Palette:
    palette = barakuda_colmap.chose_palette(cpal)    
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)

    plt.hold(True)


    if lcontours:
        cf = plt.contourf(XF, vc, cmap = palette, norm = pal_norm)
        for c in cf.collections: c.set_zorder(0.5)
    else:
        cf = plt.pcolor(XF, cmap = palette, norm = pal_norm)




    # contour for specific values on the ploted field:
    if len(vcont_spec) >= 1:
        cfs = plt.contour(XF, vcont_spec, colors='white', linewidths = 1.)
        plt.clabel(cfs, inline=1, fmt='%4.1f', fontsize=10)


    
    if lkcont:
        cfk = plt.contour(XF, vc, colors='k', linewidths = 0.1)
        for c in cfk.collections: c.set_zorder(0.75)



    # contour for continents:
    if lcontours and lcont_mask:
        cfm = plt.contour(XMSK, [ 0.7 ], colors='k', linewidths = 1.)
        for c in cfm.collections: c.set_zorder(1.)



    # Colorbar:
    # ~~~~~~~~
    clb = plt.colorbar(cf, ticks=vc, drawedges=lkcont); clb.set_label('('+cbunit+')', **font_clb)
    # Sub-sampling if needed:
    if i_sub_samp != 1:
        cb_labels = [] ; cpt = i_sub_samp
        for cr in vc:
            rr = round(float(cr),6) ; cnr = str(rr)
            if cpt == i_sub_samp:
                cpt = 1 ; cb_labels.append(cnr)
            else:
                cpt = cpt + 1 ; cb_labels.append(' ')
            clb.ax.set_yticklabels(cb_labels)

    if ( x_offset != 0. ):
        locs, labels = plt.xticks() ; jl=0; newlabels = []
        for ll in locs:
            clab = str(int(locs[jl])+int(x_offset))
            newlabels.append(clab); jl=jl+1
        plt.xticks(locs,newlabels)

    if ( y_offset != 0. ):
        locs, labels = plt.yticks() ; jl=0; newlabels = []
        for ll in locs:
            clab = str(int(locs[jl])+int(y_offset))
            newlabels.append(clab); jl=jl+1
        plt.yticks(locs,newlabels)

    plt.axis([ 0., nx-1, 0, ny-1])

    plt.title(ctitle, **font_ttl)

    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)

    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)

    return












def plot_zonal(VY, VZn, cfignm='fig', zmin=-100., zmax=100., xmin=-90., xmax=90.,
               cfig_type='pdf', cxunit=r'Latitude ($^{\circ}$N)', cyunit=' ', ctitle=' '):

    font_ttl, font_ylb, font_clb = __font_unity__()
    
    fig = plt.figure(num = 1, figsize=(11.,5.), dpi=None)
    
    ax = plt.axes([0.075, 0.11, 0.9, 0.8])   #, axisbg = 'gray')
    
    vcolo=['r','b','g', 'c', 'm', 'y', '0.75', 'r-+', 'b+']
    
    
    plt.plot(VY, VZn*0.0, 'k', linewidth=1) ; plt.hold(True)
    #
    plt.plot(VY, VZn, 'b', linewidth=2)
    #
    plt.legend(loc='lower center', shadow=True, fancybox=True)
    #
    plt.axis([xmin, xmax, zmin, zmax])
    plt.xlabel(cxunit) ; plt.ylabel(cyunit)
    plt.xticks( nmp.arange(xmin, xmax+15., 15.) )
    plt.title(ctitle, **font_ttl)
    #
    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)
    #
    plt.close(1)
    #
    return







def plot_nproj(czone, rmin, rmax, dc, xlon, xlat, XF,
               cfignm='fig', lkcont=False, cpal='jet', cbunit=' ',
               cfig_type='pdf', ctitle=' ', lforce_lim=False,
               cb_orient='vertical', i_colorbar_jump=1, dpi_fig=140):

    # Plot projection with basemap...

    #===================================================================================
    # INPUT:
    #          xlon and xlat can be 1D or 2D !!!
    #
    #===================================================================================


    
    from mpl_toolkits.basemap import Basemap
    from mpl_toolkits.basemap import shiftgrid
    import barakuda_colmap

    font_ttl, font_ylb, font_clb = __font_unity__()

    # For projections :    
    vp = __give_proj__(czone) ; # projection information


    # must work with XFtmp rather than XF, because sometimes XF is overwrited...
    [ny, nx] = nmp.shape(XF)
    XFtmp = nmp.zeros(ny*nx) ; XFtmp.shape = [ny, nx]
    XFtmp[:,:] = XF[:,:]


    if len(nmp.shape(xlat)) == 1 and len(nmp.shape(xlon)) == 1:
        if czone == 'kav7' and xlon[0] >= 0.:
            # Shifting data and longitude to be consistent with map projection
            XFtmp, xlon = shiftgrid(180.+xlon[0], XFtmp, xlon, start=False, cyclic=360.0)
        LON_2D, LAT_2D = nmp.meshgrid(xlon,xlat)
    else:
        LAT_2D = nmp.zeros(ny*nx) ; LAT_2D.shape = [ny, nx] ; LAT_2D[:,:] = xlat[:,:]
        LON_2D = nmp.zeros(ny*nx) ; LON_2D.shape = [ny, nx] ; LON_2D[:,:] = xlon[:,:]


    if lforce_lim: __force_min_and_max__(rmin, rmax, XFtmp)

    vc = __vcontour__(rmin, rmax, dc)

    # Colorbar position/size if horizontal
    vcbar = [0.1, 0.08, 0.86, 0.03]

    # Figure/canvas size:
    if cb_orient == 'horizontal':
        if czone == 'natarct':
            vfig_size = [ 5.8, 5.6 ]; vsporg = [0.08, 0.1, 0.9,  0.92]
            vcbar = [0.05, 0.08, 0.9, 0.03]
        if czone == 'npol2':
            vfig_size = [ 4.4, 5.6 ];  vsporg = [0.01, 0.15, 1., 0.8]
            vcbar = [0.05, 0.065, 0.92, 0.03]
        if czone == 'kav7':
            vfig_size = [ 8.1, 5.6 ];  vsporg = [0.001, 0.15, 1., 0.8]
            vcbar = [0.04, 0.08, 0.92, 0.03]
            
    else:
        # Vertical color bar on the rhs
        vfig_size = [ 7., 7. ]; vsporg = [0.1, 0.1, 0.85, 0.85]
        if czone == 'nseas':   vfig_size = [ 7., 5.4 ]; vsporg = [0.085,  0.03, 0.9, 0.94]
        if czone == 'natarct': vfig_size = [ 7., 7. ]; vsporg = [0.09,  0.06, 0.9, 0.85]
        if czone == 'spstere': vfig_size = [ 7., 5.8 ]; vsporg = [0.075, 0.035, 0.93, 0.93]
        if czone == 'npol2':   vfig_size = [ 7., 7.1 ]; vsporg = [0.085, 0.03, 0.91, 0.94]
        #if czone == 'kav7':    vfig_size = [ 7., 5.  ]; vsporg = [0.085, 0.03, 0.91, 0.94]
        

        
    fig = plt.figure(num = 1, figsize=(vfig_size), dpi=None, facecolor='w', edgecolor='k')
    ax  = plt.axes(vsporg, axisbg = 'w')


    ## Palette:1111
    palette = barakuda_colmap.chose_palette(cpal)    
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)
    mpl.rcParams['contour.negative_linestyle'] = 'solid'; plt.contour.negative_linestyle='solid'



    


    if vp[1] == 'lcc' or vp[1] == 'cyl' :
        carte = Basemap(llcrnrlon=vp[2],llcrnrlat=vp[3],urcrnrlon=vp[4],urcrnrlat=vp[5],\
                        resolution=vp[9],area_thresh=1000.,projection=vp[1],\
                        lat_1=vp[6],lon_0=vp[7])

    elif vp[1] == 'stere' :
        if vp[0] == 'spstere' or vp[0] == 'npstere':
            carte = Basemap(projection=vp[0], boundinglat=vp[6], lon_0=vp[7], resolution=vp[9])
        else:
            carte = Basemap(llcrnrlon=vp[2],llcrnrlat=vp[3],urcrnrlon=vp[4],urcrnrlat=vp[5],\
                          resolution=vp[9],area_thresh=1000.,projection='stere',\
                          lat_0=vp[6],lon_0=vp[7])
    elif vp[1] == 'kav' :
        print ' *** plot_nproj.barakuda_plot => Projection '+vp[0]+' / '+str(vp[7])+' / '+vp[9]
        carte = Basemap(projection=vp[0],lon_0=vp[7],resolution=vp[9])
            
    else:
        print 'ERROR: barakuda_plot.py => proj type '+vp[1]+' unknown!!!'; sys.exit(0)

    x0,y0 = carte(LON_2D,LAT_2D)


    cf = carte.contourf(x0, y0, XFtmp, vc, cmap = palette, norm = pal_norm)

        
    # Black contours if needed :
    if lkcont:
        ckf = carte.contour(x0, y0, XFtmp, vc, colors='k', linewidths=0.5)
        if cpal != 'ice':
            for c in cf.collections: c.set_zorder(0.5)   # Changing zorder so black cont. on top
        for c in ckf.collections: c.set_zorder(1.) # of filled cont. and under continents (zorder 1)

    carte.drawcoastlines() ; carte.fillcontinents(color='grey') ; carte.drawmapboundary()



    

    if vp[1] == 'lcc' or vp[1] == 'cyl':
        carte.drawmeridians(nmp.arange(-360,360,vp[8]), labels=[0,0,0,1])
        carte.drawparallels(nmp.arange( -90, 90,vp[8]), labels=[1,0,0,0])

    if vp[1] == 'stere':
        carte.drawmeridians(nmp.arange(-180,180,20), labels=[0,0,0,1])
        carte.drawparallels(nmp.arange( -90, 90,10), labels=[1,0,0,0])


    plt.title(ctitle, **font_ttl)


    # ADDING COLORBAR
    # ===============

    if cb_orient == 'horizontal':
        clbax = fig.add_axes(vcbar) # axes for colorbar
        clb   = plt.colorbar(cf, cax=clbax, ticks=vc, drawedges=lkcont, orientation='horizontal')
        for t in clb.ax.get_xticklabels(): t.set_fontsize(10)
    else:
        clb = plt.colorbar(cf, ticks=vc, drawedges=lkcont)
        for t in clb.ax.get_yticklabels(): t.set_fontsize(12)


    if i_colorbar_jump > 1:
        cn_clb = [] ; jcpt = 0
        for rtck in vc:
            if jcpt % i_colorbar_jump == 0:                
                if float(int(rtck)) == round(rtck,0):
                    cn_clb.append(str(int(rtck))) ; # we can drop the ".0"
                else:
                    cn_clb.append(str(rtck)) ; # keeping the decimals...
            else:
                cn_clb.append(' ')
            jcpt = jcpt + 1
        clb.ax.set_xticklabels(cn_clb)

    clb.set_label('('+cbunit+')', **font_clb)

    plt.savefig(cfignm+'.'+cfig_type, dpi=dpi_fig, orientation='portrait', transparent=True) ; #, transparent=True, acecolor='w', edgecolor='w',

    plt.close(1)

    del LON_2D, LAT_2D, XFtmp

    return







def sig_transport(cstck, ccr, cd_eps):

    #_____________________________________________________________
    #
    #  cstck  : root directory containing monitoring output
    #  crr    : CONF-RUN  (ex: ORCA2-GXXX)
    #  cd_eps : directory to save eps output image
    #_____________________________________________________________

    ccnf = __message__(ccr)

    cf = cstck+'/'+ccnf+'/'+ccr+'-'+'MONITOR/'+ccr+'_TRPSIG.mtl'
    print 'File =', cf, '\n'

    xmat = __get_mat__(cf)
    [nl,nc] =nmp.shape(xmat)
    print nl,nc

    vsigma = xmat[0,1:nc]   ; print 'vsigma =', vsigma, '\n' ; nbs = len(vsigma)
    vyears = xmat[1:nl:2,0] ; print 'vyears =', vyears, '\n' ; nby = len(vyears)

    print 'Number of years and sigma levels =', nby, 'and', nbs, '\n'

    X_ds = -xmat[1:nl:2,1:nc]   # Denmark Straight
    X_fb = -xmat[2:nl:2,1:nc]   # Faro Banks channel

    X_ds = nmp.ma.masked_where(X_ds  == 0, X_ds)
    X_fb = nmp.ma.masked_where(X_fb  == 0, X_fb)

    print 'Size of X_ds =',nmp.shape(X_ds)
    print 'Size of X_fb =',nmp.shape(X_fb)

    cf_eps = cd_eps+'/tsc_DS_'+ccr+'.png'
    xmt=transpose(X_ds)

    __LB_2D__(1, 0., 1.5, 30, 0.1, vyears, vsigma, xmt,
              'Transport by sigma class, Denmark Straight', cf_eps, cbunit='(Sv)')

    cf_eps = cd_eps+'/tsc_FB_'+ccr+'.eps'

    xmt=transpose(X_fb)
    __LB_2D__(1, 0., 1.5, 40, 0.1, vyears, vsigma, xmt,
              'Transport by sigma class, Denmark Straight', cf_eps,  cbunit='(Sv)')
    #
    #
    return







def plot_amoc_lat_depth(VY, VZ, Xamoc, XMSK, rmin, rmax, dc, lkcont=True, cpal='jet', ymin=-80., ymax=85., 
               cfignm='fig', cbunit='', cxunit=' ', zmin = 0., zmax = 5000., l_zlog=False,
               cfig_type='pdf', czunit=' ', ctitle=' ', lforce_lim=False):

    import math
    import matplotlib.colors as colors   # palette and co.
    import barakuda_colmap
    
    
    zVZ = nmp.zeros(len(VZ)) ; zVZ.shape = [ len(VZ) ]

    # If log / z:
    if l_zlog:
        zmin = math.log10(zmin); zmax = math.log10(zmax);
        for jk in range(len(VZ)): zVZ[jk] = math.log10(VZ[jk])
    else:
        zVZ= VZ
    
    Xamoc = nmp.ma.masked_where(XMSK == 0, Xamoc)

    if lforce_lim: __force_min_and_max__(rmin, rmax, Xamoc)

    font_ttl, font_ylb, font_clb = __font_unity__()

    fig = plt.figure(num = 1, figsize=(11.,6.), dpi=None, facecolor='w', edgecolor='k')
    ax  = plt.axes([0.07 ,  0.08,  0.99,      0.86], axisbg = 'gray')

    vc = __vcontour__(rmin, rmax, dc); #print 'plot_amoc_lat_depth: contours =>\n', vc, '\n'

    # Colormap:
    palette = barakuda_colmap.chose_palette(cpal)
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)



    # Plot:
    cf = plt.contourf(VY, zVZ, Xamoc, vc, cmap = palette, norm = pal_norm)
    plt.hold(True)
    if lkcont: plt.contour(VY, zVZ, Xamoc, vc, colors='k', linewidths=0.2)

    # Colorbar:
    clb = plt.colorbar(cf, ticks=vc); clb.set_label('('+cbunit+')', **font_clb)
    for t in clb.ax.get_yticklabels():
        t.set_fontsize(11)

    
        

    plt.axis([ ymin, ymax, zmin, zmax])
    plt.xlabel(cxunit, **font_ylb); plt.ylabel(czunit, **font_ylb)

    # Correcting ticks for log
    if l_zlog:
        locs, labels = plt.yticks(); cny = []
        print 'locs =', locs
        for jl in range(len(locs[:])): cny.append(str(int(10**locs[jl])))
        plt.yticks(locs,cny)

    plt.title(ctitle, **font_ttl)

    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)
    print cfignm+'.'+cfig_type+' created!\n'

    plt.close(1)

    return












def plot_2d_box_2f(XF1, XF2, XMSK, rmin, rmax, dc, vcont_spec2, corca='ORCA1', lkcont=True,
                cpal='jet', cfignm='fig', cbunit='', ctitle=' ', lforce_lim=False,
                i_sub_samp=1, cfig_type='pdf', lcontours=True,
                x_offset=0., y_offset=0., vcont_spec1 = []):

    # Take 2 fields as imput and shows contours of second field (vcont_spec2) on top of field 1

    import numpy as nmp
    import matplotlib.colors as colors   # palette and co.
    import barakuda_colmap


    if nmp.shape(XF1) != nmp.shape(XF2):
        print 'ERROR barakuda_plot.plot_2d_box_2f: fields F1 and F2 dont have the same shape!'
        sys.exit(0)



    font_ttl, font_ylb, font_clb = __font_unity__()


    if lforce_lim: __force_min_and_max__(rmin, rmax, XF1)

    [ ny , nx ] = XF1.shape
    vert_rat = float(ny)/float(nx)
    print "Vert. ratio, nx, ny =", vert_rat, nx, ny

    # Masking field:
    if lcontours:
        idxm = nmp.where(XMSK[:,:] == 0); XF1[idxm] = -9999.9  # c'est NaN qui merde!!!
    else:
        XF1 = nmp.ma.masked_where(XMSK == 0, XF1)


    
    # FIGURE
    # ~~~~~~
    fig = plt.figure(num = 1, figsize=(7.,6.*vert_rat), dpi=None, facecolor='w', edgecolor='k')

    ax = plt.axes([0.07, 0.05, 0.9, 0.9], axisbg = 'gray')

    vc = __vcontour__(rmin, rmax, dc); #print vc, '\n'

    # Palette:
    palette = barakuda_colmap.chose_palette(cpal)    
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)

    plt.hold(True)


    if lcontours:
        cf = plt.contourf(XF1, vc, cmap = palette, norm = pal_norm)
        for c in cf.collections: c.set_zorder(0.5)
    else:
        cf = plt.pcolor(XF1, cmap = palette, norm = pal_norm)

    # contour for specific values on the ploted field:
    if len(vcont_spec1) >= 1:
        cfs1 = plt.contour(XF1, vcont_spec1, colors='white', linewidths = 1.)
        plt.clabel(cfs1, inline=1, fmt='%4.1f', fontsize=10)

    # Contours of field F2:
    cfs2 = plt.contour(XF2, vcont_spec2, colors='r', linewidths = 1.3)
    #plt.clabel(cfs1, inline=1, fmt='%4.1f', fontsize=10)

    
    if lkcont:
        cfk = plt.contour(XF1, vc, colors='k', linewidths = 0.1)
        for c in cfk.collections: c.set_zorder(0.75)





    # contour for continents:
    if lcontours:
        cfm = plt.contour(XMSK, [ 0.7 ], colors='k', linewidths = 0.4)
        for c in cfm.collections: c.set_zorder(1.)



    # Colorbar:
    # ~~~~~~~~
    clb = plt.colorbar(cf, ticks=vc, drawedges=lkcont); clb.set_label('('+cbunit+')', **font_clb)
    # Sub-sampling if needed:
    if i_sub_samp != 1:
        cb_labels = [] ; cpt = i_sub_samp
        for cr in vc:
            rr = round(float(cr),6) ; cnr = str(rr)
            if cpt == i_sub_samp:
                cpt = 1 ; cb_labels.append(cnr)
            else:
                cpt = cpt + 1 ; cb_labels.append(' ')
            clb.ax.set_yticklabels(cb_labels)

    if ( x_offset != 0. ):
        locs, labels = plt.xticks() ; jl=0; newlabels = []
        for ll in locs:
            clab = str(int(locs[jl])+int(x_offset))
            newlabels.append(clab); jl=jl+1
        plt.xticks(locs,newlabels)

    if ( y_offset != 0. ):
        locs, labels = plt.yticks() ; jl=0; newlabels = []
        for ll in locs:
            clab = str(int(locs[jl])+int(y_offset))
            newlabels.append(clab); jl=jl+1
        plt.yticks(locs,newlabels)

    plt.axis([ 0., nx-1, 0, ny-1])

    plt.title(ctitle, **font_ttl)

    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)

    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)

    del Xtmp

    return




    

def plot_trsp_sig_class(VT, vsigma_bounds, XF, rmin, rmax, dc, dsig,
                        lkcont=True, cpal='sigtr', dt_year=5., cfignm='fig', 
                        cfig_type='pdf', ctitle='', lforce_lim=False, vcont_spec1 = [],
                        i_colorbar_jump=2):

    # Plot transport by sigma class...
    
    import matplotlib.colors as colors   # palette and co.
    import barakuda_colmap

    font_ttl, font_ylb, font_clb = __font_unity__()
    
    if lforce_lim: __force_min_and_max__(rmin, rmax, XF)

    fig = plt.figure(num = 1, figsize=(WDTH_TS,7.2), dpi=None, facecolor='w', edgecolor='k')
    ax = plt.axes([0.055,  -0.025, 0.93, 0.98], axisbg = 'white')


    vc = __vcontour__(rmin, rmax, dc); #print 'plot_time_depth_hovm: contours =>\n', vc, '\n'

    nbins = len(vsigma_bounds) - 1

    # Palette:
    palette = barakuda_colmap.chose_palette(cpal)
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)
    mpl.rcParams['contour.negative_linestyle'] = 'solid'
    plt.contour.negative_linestyle='solid'

    cf = plt.contourf(VT, vsigma_bounds[:-1], XF, vc, cmap = palette, norm = pal_norm)
    #cf = plt.pcolor(VT, vsigma_bounds[:-1], XF, cmap = palette, norm = pal_norm)
    if lkcont:
        cfc = plt.contour(VT, vsigma_bounds[:-1], XF, nmp.arange(-3.,3.,0.5), colors='k', linewidths=0.4)

    # contour for specific values on the ploted field:
    if len(vcont_spec1) >= 1:
        cfs1 = plt.contour(VT, vsigma_bounds[:-1], XF, vcont_spec1, colors='white', linewidths = 1.)
        plt.clabel(cfs1, inline=1, fmt='%4.1f', fontsize=11, manual=[(2080,2.)] )


    # COLOR BAR
    clb = plt.colorbar(cf, ticks=vc, drawedges=True, orientation='horizontal', pad=0.09, shrink=1., aspect=40)
    if i_colorbar_jump > 1:
        cn_clb = [] ; jcpt = 0
        for rtck in vc:
            if jcpt % i_colorbar_jump == 0: cn_clb.append('%.1f' % rtck)
            else: cn_clb.append(' ')
            jcpt = jcpt + 1
        clb.ax.set_xticklabels(cn_clb)
    for t in clb.ax.get_xticklabels(): t.set_fontsize(12)
    font = { 'fontsize':12 }
    clb.set_label('(Sv)', **font)


    # AXES:
    y1 = int(min(VT))  ; y2 = int(max(VT))+1
    plt.axis([y1, y2, vsigma_bounds[nbins], vsigma_bounds[0]])
    plt.xticks( nmp.arange(y1, y2+dt_year, dt_year) )
    plt.yticks( nmp.flipud(vsigma_bounds) )

    label_big = { 'fontname':'Trebuchet MS', 'fontweight':'normal', 'fontsize':18 }
    plt.ylabel(r'$\sigma_0$', **label_big)

    plt.title(ctitle, **font_ttl)
    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)
    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)

    return












def plot_vert_section_extra(VX, VZ, XF, XMSK, Vcurve, rmin, rmax, dc, lkcont=True, cpal='jet', xmin=-80., xmax=85., 
                            cfignm='fig', cbunit='', cxunit=' ', zmin = 0., zmax = 5000., l_zlog=False,
                            cfig_type='pdf', czunit=' ', ctitle=' ', lforce_lim=False, fig_size=(8.,8.) ):
    
    import math
    import matplotlib.colors as colors   # palette and co.
    import barakuda_colmap
    
    
    zVZ = nmp.zeros(len(VZ)) ; zVZ.shape = [ len(VZ) ]

    # If log / z:
    if l_zlog:
        zmin = math.log10(zmin); zmax = math.log10(zmax);
        for jk in range(len(VZ)): zVZ[jk] = math.log10(VZ[jk])
    else:
        zVZ= VZ
    
    
    XF = nmp.ma.masked_where(XMSK == 0, XF)
    
    if lforce_lim: __force_min_and_max__(rmin, rmax, XF)

    font_ttl, font_ylb, font_clb = __font_unity__()

    
    fig = plt.figure(num = 1, figsize=fig_size, dpi=None, facecolor='w', edgecolor='k')
    ax = plt.axes([0.1,  0.065,   0.92,       0.89], axisbg = 'gray')
    vc = __vcontour__(rmin, rmax, dc)

    # Palette:
    palette = barakuda_colmap.chose_palette(cpal)
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)

    cf = plt.contourf(VX, zVZ, XF, vc, cmap = palette, norm = pal_norm)
    plt.hold(True)
    if lkcont: plt.contour(VX, zVZ, XF, vc, colors='k', linewidths=0.2)

    clb = plt.colorbar(cf, ticks=vc)
    for t in clb.ax.get_yticklabels():
        t.set_fontsize(10)

    plt.axis([ xmin, xmax, zmax, zmin])
    plt.xlabel(cxunit, **font_ylb); plt.ylabel(czunit, **font_ylb)

    plt.plot(VX,Vcurve, 'w', linewidth=2)

    for zz in zVZ[:]:
        plt.plot(VX,VX*0.+zz, 'k', linewidth=0.3)


    # Correcting ticks for log
    if l_zlog:
        locs, labels = plt.yticks(); cny = []
        print 'locs =', locs
        for jl in range(len(locs[:])): cny.append(str(int(10**locs[jl])))
        plt.yticks(locs,cny)
    plt.axis([ xmin, xmax, zmax, zmin])

    plt.title(ctitle, **font_ttl)
    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)
    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)
    #
    return









def plot_time_depth_hovm(VT, VZ, XF, XMSK, rmin, rmax, dc, lkcont=True, cpal='jet',
                         tmin=0., tmax=100., dt=5.,
                         cfignm='fig', cbunit='', cxunit=' ', zmin = 0., zmax = 5000., l_zlog=False,
                         cfig_type='pdf', czunit=' ', ctitle=' ', lforce_lim=False, vcont_spec1 = []):
    #************************************************************************
    
    import math
    import matplotlib.colors as colors   # palette and co.
    import barakuda_colmap


    font_ttl, font_ylb, font_clb = __font_unity__()

    
    zVZ = nmp.zeros(len(VZ)) ; zVZ.shape = [ len(VZ) ]

    # If log / z:
    if l_zlog:
        zmin = math.log10(zmin); zmax = math.log10(zmax);
        for jk in range(len(VZ)): zVZ[jk] = math.log10(VZ[jk])
    else:
        zVZ[:] = VZ[:]
    
    
    XF = nmp.ma.masked_where(XMSK == 0, XF)

    if lforce_lim: __force_min_and_max__(rmin, rmax, XF)

#---------------------------------------------------------

    fig = plt.figure(num = 1, figsize=(11.,4.), dpi=None, facecolor='w', edgecolor='k')
    ax = plt.axes([0.07,  0.08,   1., 0.82], axisbg = 'gray')


    vc = __vcontour__(rmin, rmax, dc); #print 'plot_time_depth_hovm: contours =>\n', vc, '\n'

    # Palette:
    palette = barakuda_colmap.chose_palette(cpal)
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)

    cf = plt.contourf(VT, zVZ, XF, vc, cmap = palette, norm = pal_norm)
    plt.hold(True)
    if lkcont: plt.contour(VT, zVZ, XF, vc, colors='k', linewidths=0.2)

    # contour for specific values on the ploted field:
    if len(vcont_spec1) >= 1:
        cfs1 = plt.contour(VT, zVZ, XF, vcont_spec1, colors='white', linewidths = 1.)
        plt.clabel(cfs1, inline=1, fmt='%4.1f', fontsize=11, manual=[(2080,2.)] )

    
    clb = plt.colorbar(cf, ticks=vc)
    for t in clb.ax.get_yticklabels():
        t.set_fontsize(12)
    clb.set_label('('+cbunit+')', **font_clb)
    
    plt.axis([ tmin, tmax, zmax, zmin])
    #plt.xlabel(cxunit);
    plt.ylabel(czunit, **font_ylb)
    
    #Correcting ticks for log
    if l_zlog:
        locs, labels = plt.yticks(); cny = []
        for jl in range(len(locs[:])): cny.append(str(int(10.**locs[jl])))
        plt.yticks(locs,cny)
    plt.axis([ tmin, tmax, zmax, zmin])

    
    plt.xticks( nmp.arange(tmin, tmax+dt, dt) )

    plt.title(ctitle, **font_ttl)
    plt.savefig(cfignm+'.'+cfig_type, dpi=100, orientation='portrait', transparent=True)
    print cfignm+'.'+cfig_type+' created!\n'
    plt.close(1)

    return









def plot_enso(VT, VSST, cfignm='fig', dt_year=5):

    font_ttl, font_ylb, font_clb = __font_unity__()

    Nt = len(VT)

    if len(VT) != len(VSST): print 'ERROR: plot_enso.barakuda_plot => VT and VSST do not agree in size'; sys.exit(0)

    print ' Nt =>', Nt

    # Array to contain nino series:
    xnino = nmp.zeros(Nt*4) ; xnino.shape = [ Nt, 4 ]

    xnino[:,0] = VSST[:]

    # 5-month running mean:
    for jt in nmp.arange(2,Nt-2):
        xnino[jt,1] = (xnino[jt-2,0] + xnino[jt-1,0] + xnino[jt,0] + xnino[jt+1,0] + xnino[jt+2,0]) / 5.

    xnino[0:2,1] = xnino[2,1] ; xnino[Nt-2:Nt,1] = xnino[Nt-3,1]

    print '\n'

    print 'mean value for sst mean = ', nmp.sum(xnino[:,0])/Nt
    print 'mean value for sst 5-m-r mean = ', nmp.sum(xnino[:,1])/Nt


    # least-square curve for 5-month running mean:
    sumx  = nmp.sum(VT[:]) ; sumy  = nmp.sum(xnino[:,1])
    sumxx = nmp.sum(VT[:]*VT[:])
    sumxy = nmp.sum(VT[:]*xnino[:,1])
    a = ( sumx*sumy - Nt*sumxy ) / ( sumx*sumx - Nt*sumxx )
    b = ( sumy - a*sumx ) / Nt
    print 'a, b =', a, b

    # least-square linear trend:
    xnino[:,2] = a*VT[:] + b
    print 'mean value for least-square linear trend = ', nmp.sum(xnino[:,2])/Nt

    # anomaly
    xnino[:,3] = xnino[:,1] - xnino[:,2] ; # anomaly for 5-month running mean
    print 'mean value for anomaly = ', nmp.sum(xnino[:,3])/Nt

    # FIGURE ENSO
    #############

    vsst_plus  = nmp.zeros(Nt) ; vsst_plus.shape = [ Nt ]
    vsst_minus = nmp.zeros(Nt) ; vsst_minus.shape = [ Nt ]
    
    vsst_plus[:]  = xnino[:,3]
    vsst_minus[:] = xnino[:,3]

    vsst_plus[nmp.where(xnino[:,3] < 0. )] = 0.
    vsst_minus[nmp.where(xnino[:,3] > 0. )] = 0.

    vsst_plus[0] = 0. ; vsst_minus[0] = 0.
    vsst_plus[Nt-1] = 0. ; vsst_minus[Nt-1] = 0.

    y1 = int(min(VT))
    y2 = int(max(VT)+0.25)
    
    fig = plt.figure(num = 2, figsize=FIG_SIZE_TS, facecolor='w', edgecolor='k')

    ax = plt.axes(AXES_TS)

    xnino[:,0] =  0.4 ; plt.plot(VT, xnino[:,0], 'r--', linewidth=1.5)
    xnino[:,0] = -0.4 ; plt.plot(VT, xnino[:,0], 'b--', linewidth=1.5)

    plt.fill(VT, vsst_plus, 'r', VT, vsst_minus, 'b', linewidth=0)
    plt.plot(VT, xnino[:,3], 'k', linewidth=0.7)
    xnino[:,3] = 0.0
    plt.plot(VT, xnino[:,3], 'k', linewidth=0.7)
    plt.axis([min(VT), max(VT), -2.5, 2.5])

    #plt.xticks( nmp.arange(trunc(VT[0]), trunc(max(VT[:]))+dt_year, dt_year) )
    plt.xticks( nmp.arange(y1, y2+dt_year, dt_year) )

    
    plt.yticks( nmp.arange(-2.5,2.501,0.5) )

    ax.grid(color='k', linestyle='-', linewidth=0.2)
    plt.ylabel(r'SST anomaly ($^{\circ}$C)')
    plt.title('SST anomaly on Nino region 3.4')
    cf_fig = cfignm+'.png'
    plt.savefig(cf_fig, dpi=DPI_TS, orientation='portrait', transparent=True)

    plt.close(2)


    del xnino

    return









def plot_1d_mon_ann(VTm, VTy, VDm, VDy, cfignm='fig', dt_year=5, cyunit='', ctitle='',
                    ymin=0, ymax=0, dy=0, mnth_col='b', plt_m03=False, plt_m09=False,
                    cfig_type='png', l_tranparent_bg=True):

    #
    # if you specify ymin and ymax you can also specify y increment (for y grid) as dy
    #
    # plt_m03 => plot march values on top in green
    # plt_m09 => plot september values on top in green

    font_ttl, font_ylb, font_clb = __font_unity__()

    Nt1 = len(VTm) ; Nt2 = len(VTy)

    if len(VTm) != len(VDm): print 'ERROR: plot_1d_mon_ann.barakuda_plot => VTm and VDm do not agree in size'; sys.exit(0)
    if len(VTy) != len(VDy): print 'ERROR: plot_1d_mon_ann.barakuda_plot => VTy and VDy do not agree in size'; sys.exit(0)

    fig = plt.figure(num = 1, figsize=FIG_SIZE_TS, facecolor='w', edgecolor='k')

    ax = plt.axes(AXES_TS)

    plt.plot(VTm, VDm, mnth_col, label=r'monthly', linewidth=1)
    plt.plot(VTy, VDy, 'r', label=r'annual', linewidth=2)

    if plt_m03: plt.plot(VTm[2:Nt1:12], VDm[2:Nt1:12], 'orange', label=r'March',     linewidth=2)
    if plt_m09: plt.plot(VTm[8:Nt1:12], VDm[8:Nt1:12], 'orange', label=r'September', linewidth=2)

    if plt_m03 or plt_m09: plt.legend(loc='lower center', shadow=True, fancybox=True)


    y1 = int(min(VTy)-0.5)
    y2 = int(max(VTy)+0.5)

    mean_val = nmp.mean(VDy)
    df = max( abs(min(VDm)-mean_val), abs(max(VDm)-mean_val) )

    if ymin==0 and ymax==0:
        plt.axis( [y1, y2, min(VDm)-0.2*df, max(VDm)+0.2*df] )
    else:
        plt.axis([y1, y2, ymin,     ymax])
        if dy != 0: plt.yticks( nmp.arange(trunc(ymin+0.5), trunc(ymax)+dy, dy) )

    y_formatter = mpl.ticker.ScalarFormatter(useOffset=False)
    ax.yaxis.set_major_formatter(y_formatter)


    plt.xticks( nmp.arange(y1, y2+dt_year, dt_year) )

    #BUG?:
    locs, labels = plt.xticks() ; jl=0; newlabels = []
    for ll in locs: newlabels.append(str(int(locs[jl]))); jl=jl+1
    plt.xticks(locs,newlabels)
    #BUG?.

    #plt.xlim((y1, y2))
    
    ax.grid(color='k', linestyle='-', linewidth=0.2)

    plt.ylabel('('+cyunit+')', **font_ylb)

    plt.title(ctitle)
    
    cf_fig = cfignm+'.'+cfig_type

    plt.savefig(cf_fig, dpi=DPI_TS, orientation='portrait', transparent=l_tranparent_bg)
    
    plt.close(1)








def plot_1d_multi(vt, XD, vlabels, cfignm='fig', dt_year=5, i_t_jump=1, cyunit='', ctitle='',
                  cfig_type='png', ymin=0, ymax=0, lzonal=False, xmin=0, xmax=0,
                  loc_legend='lower center', line_styles=[], fig_size=FIG_SIZE_TS,
                  l_tranparent_bg=True):

    # lzonal => zonally averaged curves...
    
    if lzonal:
        font_ttl, font_big_fixed, font_ylb, font_clb = __font_unity_big__()
    else:
        font_ttl, font_ylb, font_clb = __font_unity__()

    # Number of lines to plot:
    [ nb_plt, nbt ] = XD.shape

    if len(vt) != nbt: print 'ERROR: plot_1d_multi.barakuda_plot.py => vt and XD do not agree in shape!'; sys.exit(0)
    if len(vlabels) != nb_plt: print 'ERROR: plot_1d_multi.barakuda_plot.py => wrong number of labels...'; sys.exit(0)

    n0 = len(line_styles)
    if n0 > 0 and n0 != nb_plt: print 'ERROR: plot_1d_multi.barakuda_plot.py => wrong number line styles!!!'; sys.exit(0)
        


    # Masking the time-series shorter than others (masked with -999.)
    XD = nmp.ma.masked_where(XD < -900., XD)

    if lzonal:
        fig = plt.figure(num = 1, figsize=(8.,5), facecolor='w', edgecolor='k')
        ax = plt.axes([0.09, 0.11, 0.88, 0.83])
    else:
        fig = plt.figure(num = 1, figsize=FIG_SIZE_TS, facecolor='w', edgecolor='k')
        ax = plt.axes(AXES_TS)

    if lzonal: plt.plot(vt[:], XD[0,:]*0., 'k', linewidth=1)

    for jp in range(nb_plt):
        if n0 > 0:
            plt.plot(vt[:], XD[jp,:], line_styles[jp], label=vlabels[jp], linewidth=2)
        else:
            plt.plot(vt[:], XD[jp,:],                  label=vlabels[jp], linewidth=2)


    plt.legend(loc=loc_legend, ncol=int(nb_plt/4+1), shadow=True, fancybox=True)


    if lzonal:
        dt_year = 15. ; # x-axis increment (latitude!)
        if xmin == 0 and xmax == 0:
            y1 = -90. ; y2 = 90.
        else:
            y1 = xmin ;  y2 = xmax
    else:
        if xmin == 0 and xmax == 0:
            y1 = trunc(vt[0])
            y2 = int(round(vt[len(vt)-1]+0.4))
        else:
            y1 = xmin ; y2 = xmax

    if ymin==0 and ymax==0:
        mean_val = nmp.mean(XD[:,:])
        df = max( abs(nmp.min(XD[:,:])-mean_val), abs(nmp.max(XD[:,:])-mean_val) )
        plt.axis( [y1, y2, nmp.min(XD[:,:])-0.2*df, nmp.max(XD[:,:])+0.2*df] )
    else:
        plt.axis([y1, y2, ymin,     ymax])


    print 'y1, y2 =', y1, y2 

    if lzonal:
        plt.xticks( nmp.arange(y1, y2+10, 10) )
        
    else:
        plt.xticks( nmp.arange(y1, y2+dt_year, dt_year) )
        if i_t_jump > 1:
            locs, labels = plt.xticks() ; new_t_labels = []
            jcpt = 1 ; # => tick priting will start at y1+dt_year on x axis rather than y1
            for tt in locs:
                if jcpt % i_t_jump == 0:                
                    new_t_labels.append(str(int(tt))) ; # keeping the decimals...
                else:
                    new_t_labels.append(' ')
                jcpt = jcpt + 1
            plt.xticks(locs,new_t_labels)
        ax.set_xlim(y1, y2)
        
    ax.grid(color='k', linestyle='-', linewidth=0.2)

    if lzonal: plt.xlabel(r'Latitude ($^{\circ}$N)', **font_ylb)
        
    plt.ylabel('('+cyunit+')', **font_ylb)

    plt.title(ctitle, **font_ttl)

    cf_fig = cfignm+'.'+cfig_type




    plt.savefig(cf_fig, dpi=DPI_TS, orientation='portrait', transparent=l_tranparent_bg)
    
    plt.close(1)
    print '   => Multi figure "'+cf_fig+'" created!'






def check_with_fig_2(x2d, msk, cname, rmin=999., rmax=-999., cpal='jet', fig_type='png'):

    import barakuda_colmap

    font_ttl, font_ylb, font_clb = __font_unity__()

    [ ny, nx ] = x2d.shape

    if x2d.shape != msk.shape:
        print 'ERROR: check_with_fig_2.barakuda_plot.py => x2d and msk do not agree in size!'; sys.exit(0)

    if rmin ==  999. : rmin = nmp.amin(x2d)
    if rmax == -999. : rmax = nmp.amax(x2d)
    
    x2d = nmp.ma.array(x2d, mask=-msk+1)

    fig = plt.figure(num = 1, figsize=(8.,7.), dpi=None, facecolor='w', edgecolor='k')
    
    ax  = plt.axes([0.09, 0.06, 0.9, 0.9], axisbg = 'gray')

    # Palette:
    palette = barakuda_colmap.chose_palette(cpal)

    print 'rmin, rmax = ', rmin, rmax

    # Tout ce qui depasse de la pallete a sa couleur changee!!!
    palette.set_over('k', 1.0)
    palette.set_under('w', 1.0)
    #palette.set_bad('w', 1.0)


    
    pal_norm = colors.Normalize(vmin = rmin, vmax = rmax, clip = False)

    cf = plt.pcolor(x2d, cmap = palette, norm = pal_norm, edgecolors='none')

    plt.clim(vmin=rmin, vmax=rmax)
    plt.axis([ 0, nx, 0, ny])
    clb = plt.colorbar(cf)
    clb.set_label('(deg.C)')

    plt.xlabel('i', **font_ylb); plt.ylabel('j', **font_ylb)

    
    plt.savefig('fig_'+cname+'.'+fig_type, dpi=100, orientation='portrait', transparent=True)

    print 'fig_'+cname+'.'+fig_type+' created !!!\n'
    
    plt.close(1)











# LOCAL functions
# ===============




def __message__(ccr):

    # Find the CONF from CONF-RUN and exit if CONF does not exist!
    i = 0 ; conf = ''
    while i < len(ccr) and ccr[i] != '-' : conf = conf+ccr[i]; i=i+1
    print 'conf =', conf, '\n'
    return conf



def __get_mat__(cf):

    f1 = open(cf, 'r') # for reading
    lines1=f1.readlines()
    f1.close()

    zm   = []
    jy   = 0

    for l in lines1:
        if l[0] != '#':
            jy = jy + 1
            ls = l.split()
            zm.append([])
            for c in ls:
                zm[jy-1].append(float(c))

    zxm = array(zm)
    print 'Shape zxm = ',nmp.shape(zxm), '\n'
    return zxm



def __vcontour__(zmin, zmax, zdc):
    #
    #
    lngt = zmax - zmin
    #
    ncont = lngt/zdc
    #
    vcont = nmp.arange(zmin, zmax + zdc, zdc)
    #
    #lat_min
    return vcont



def __name_coor_ticks__(lon_ext=0):
    #
    # Builds nice ticks for X and Y (lon, lat) axes!
    #
    # Arrange longitude axis !
    VX = nmp.arange(0, 360+lon_ext+30, 30); VX0 = nmp.arange(0, 360+lon_ext+30, 30);
    ivf = nmp.where(VX>180); VX0[ivf] = VX[ivf] - 360
    cn_lon = []
    for jlon in VX0:
        if jlon < 0:
            cn_lon.append(str(-jlon)+r'$^{\circ}$W')
        else:
            if jlon == 0:
                cn_lon.append(str(jlon)+r'$^{\circ}$')
            else:
                cn_lon.append(str(jlon)+r'$^{\circ}$E')
    #
    # Arrange latitude axis !
    VY = nmp.arange(-90, 90+15, 15)
    cn_lat = []
    for jlat in VY:
        if jlat < 0:
            cn_lat.append(str(-jlat)+r'$^{\circ}$S')
        else:
            if jlat == 0:
                cn_lat.append(str(jlat)+r'$^{\circ}$')
            else:
                cn_lat.append(str(jlat)+r'$^{\circ}$N')
    #
    return VX, VY, cn_lon, cn_lat



def __give_proj__(cname):
    #
    #
    nb =nmp.shape(projection_def)[0] ; #print 'nb =', nb
    #
    # Initializing :
    vproj = [ 'NC', 'NC', 0.,  0.,  0.,  0.,  0.,  0., 'NC' ]
    #
    #
    jb = 0
    while jb < nb :
        if projection_def[jb][0] == cname:
            break
        else :
            jb = jb + 1
    #
    if jb == nb :
        print 'Zone "'+cname+'" does not exist!\n'
        print 'so far choice is :'
        for jb in range(nb): print projection_def[jb][0]
        sys.exit(0)
        #
        #
    vproj = projection_def[jb][:]
    #
    #print 'For ', projection_def[jb][0], ' we have vproj =', vproj, '\n'
    #
    return vproj





def __font_unity__():
    #
    params = {'font.family':'Trebuchet MS','text.fontsize':15,'xtick.labelsize':14,'ytick.labelsize': 14,'axes.labelsize':14}
    mpl.rcParams.update(params)    
    big_fixed_fonts = { 'fontname':'monaco',       'fontweight':'normal', 'fontsize':15 }
    label_fonts     = { 'fontname':'Trebuchet MS', 'fontweight':'normal', 'fontsize':14 }
    colorbar_fonts  = { 'fontname':'Tahoma',       'fontweight':'normal', 'fontsize':12 }    
    return big_fixed_fonts, label_fonts, colorbar_fonts




def __force_min_and_max__(rm, rp, Xin):
    idx_bad  = nmp.where(nmp.logical_not(nmp.isfinite(Xin)))
    Xin[idx_bad] = 0.
    idx1 = nmp.where(Xin <= rm); Xin[idx1] = rm + abs(rp-rm)*1.E-4
    idx2 = nmp.where(Xin >= rp); Xin[idx2] = rp - abs(rp-rm)*1.E-4
    Xin[idx_bad] = nmp.nan


def __font_unity_big__():
    #
    params = {'font.family':'Trebuchet MS','text.fontsize':20,'xtick.labelsize':16,'ytick.labelsize': 16,'axes.labelsize':18}
    mpl.rcParams.update(params)
    title_fonts     = { 'fontname':'Trebuchet MS', 'fontweight':'normal', 'fontsize':20 }
    big_fixed_fonts = { 'fontname':'monaco',       'fontweight':'normal', 'fontsize':20 }
    label_fonts     = { 'fontname':'Trebuchet MS', 'fontweight':'normal', 'fontsize':16 }
    colorbar_fonts  = { 'fontname':'Tahoma',       'fontweight':'normal', 'fontsize':14 }    
    return title_fonts, big_fixed_fonts, label_fonts, colorbar_fonts
    



#    params = { 'font.family': 'Ubuntu Mono',
#               'legend.fontsize': 14,
#               'text.fontsize':   14,
#               'xtick.labelsize': 12,
#               'ytick.labelsize': 12,
#               'axes.labelsize':  14}
#    mpl.rcParams.update(params)
#
#    font_ttl = { 'fontname':'Bitstream Vera Sans Mono', 'fontweight':'normal', 'fontsize':14 }
#    font_ylb = { 'fontname':'Tahoma', 'fontweight':'normal', 'fontsize':12 }
