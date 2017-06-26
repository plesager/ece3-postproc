import numpy as nmp
import sys





def chck4f(cf, script_name=''):
    import os
    
    cmesg = 'ERROR: File '+cf+' does not exist !!!'
    if script_name != '': cmesg = 'ERROR in script '+script_name+': File '+cf+' does not exist !!!'
    
    if not os.path.exists(cf):
        print cmesg ; sys.exit(0)
    else:
        print '\n   *** will open file '+cf


def iaxe_tick(ny):
    # I want 20 ticks on the absciss axe and multiple of 5
    itick = int( max( 1 , min(ny/20 , max(ny/20,5)/5*5) ) )
    if itick == 4 or itick == 3: itick = 5
    return itick


def monthly_2_annual(vtm, XDm):

    # Transform a montly time series into an annual time series

    nbm = len(vtm)

    if len(nmp.shape(XDm)) == 1:
        # XDm is a vector
        nbcol = 1
        nt    = len(XDm)
    else:
        # XDm is an array
        [ nbcol, nt ] = nmp.shape(XDm)
        
    #print 'nbcol, nt => ', nbcol, nt


    if nt != nbm: print 'ERROR: vmonthly_2_vannual.barakuda_tool.py => vt and vd disagree in size!'; sys.exit(0)
    if nbm%12 != 0: print 'ERROR: vmonthly_2_vannual.barakuda_tool.py => not a multiple of 12!'; sys.exit(0)
    
    nby = nbm/12
    vty = nmp.zeros(nby)
    XDy = nmp.zeros(nbcol*nby) ; XDy.shape = [nbcol,nby]

    #print 'DEBUG: monthly_2_annual.barakuda_tool.py => nbm, nby, nbcol:', nbm, nby, nbcol

    for jy in range(nby):
        jt_jan = jy*12        
        vty[jy] = nmp.trunc(vtm[jt_jan]) + 0.5 ; #  1992.5, not 1992

        if nbcol == 1:
            XDy[0,jy] = nmp.mean(XDm[jt_jan:jt_jan+12])
        else:
            XDy[:,jy] = nmp.mean(XDm[:,jt_jan:jt_jan+12], axis=1)

    if nbcol == 1:
        return vty, XDy[0,:]
    else:
        #print 'DEBUG: monthly_2_annual.barakuda_tool.py => shape(vty):', nmp.shape(vty)
        return vty, XDy
         


def find_ij_region_box(vbox4, VX, VY):

    [x_min, y_min, x_max, y_max ] = vbox4

    print ''
    print 'barakuda_tool.find_ij_region_box : x_min, y_min, x_max, y_max => ', x_min, y_min, x_max, y_max


    # fixing longitude:
    # ~~~~~~~~~~~~~~~~~
    if x_min < 0. : x_min = x_min + 360.
    if x_max < 0. : x_max = x_max + 360.

    VXtmp = nmp.zeros(len(VX)) ; VXtmp[:] = VX[:]
    idx = nmp.where(VX[:] < 0.0) ; VXtmp[idx] = VX[idx] + 360.


    # fixing latitude:
    # ~~~~~~~~~~~~~~~~~

    # Is latitude increasing with j ?
    jy_inc = 1
    if VY[1] < VY[0]: jy_inc = -1

    #print jy_inc
    
    #VYtmp = nmp.zeros(len(VY)) ; VYtmp[:] = VY[:]

    j_y_min = find_index_from_value( y_min, VY )
    j_y_max = find_index_from_value( y_max, VY )
    i_x_min = find_index_from_value( x_min, VXtmp )
    i_x_max = find_index_from_value( x_max, VXtmp )

    if i_x_min == -1 or i_x_max == -1 or j_y_min == -1 or j_y_max == -1:
        print 'ERROR: barakuda_tool.find_ij_region_box, indiex not found'
        sys.exit(0)
            
    if jy_inc == -1: jdum = j_y_min; j_y_min = j_y_max; j_y_max = jdum

    #print '  * i_x_min = ', i_x_min, ' => ', VX[i_x_min]
    #print '  * j_y_min = ', j_y_min, ' => ', VY[j_y_min]
    #print '  * i_x_max = ', i_x_max, ' => ', VX[i_x_max]
    #print '  * j_y_max = ', j_y_max, ' => ', VY[j_y_max]
    #print '\n'

    return [ i_x_min, j_y_min, i_x_max, j_y_max ]

#-----------------------------------


def read_ascii_column(cfile, ivcol2read):
    #
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # INPUT
    #       cfile       : ASCII file
    #       ivcol2read  : vector containing indices of colum to be read (ex: [0, 1, 4])
    #
    # OUTPUT
    #      Xout         : array containg the extracted data
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    chck4f(cfile)
    f = open(cfile, 'r')
    cread_lines = f.readlines()
    f.close()
    #
    nbcol = len(ivcol2read) ; #print "nbcol = ", nbcol
    #
    # Need to know how many "non-comment" lines:
    jl = 0
    for ll in cread_lines:
        ls = ll.split()
        if ls[0] != '#': jl = jl + 1
    nbl = jl
    #print 'number of lines = ', nbl ; sys.exit
    #
    Xout  = nmp.zeros(nbcol*nbl) ; Xout.shape = [nbcol,nbl]
    #
    jl = -1
    for ll in cread_lines:
        ls = ll.split()
        if ls[0] != '#':
            jl = jl+1
            jc = -1
            for icol in ivcol2read:
                jc = jc+1
                Xout[jc,jl] = float(ls[icol])
    #
    return Xout





def get_min_max_df(ZZ, ndf):

    import math
    
    # RETURNS rounded Min and Max of array ZZ as well as the contour interval for "ndf" contours...

    # Testing where the array has finite values (non nan, non infinite)
    Lfinite = nmp.isfinite(ZZ)
    idx_good = nmp.where(Lfinite)

    zmin = nmp.amin(ZZ[idx_good]) ; zmax = nmp.amax(ZZ[idx_good])

    if abs(zmin) >= abs(zmax):
        zmax = -zmin
    else:
        zmin = -zmax


    zmin0 = zmin ; zmax0 = zmax

    #print ' Before in barakuda_tool.get_min_max_df: zmin, zmax =', zmin, zmax

    rmagn = 10.**(int(math.log10(zmax)))

    zmin = round(zmin/rmagn - 0.5)
    zmax = round(zmax/rmagn + 0.5)

    zdf0 = (zmax - zmin)/ndf

    zdf = 0.0 ; idec = 0
    while zdf == 0.0:
        idec = idec + 1
        zdf = round(zdf0,idec)

    if idec >= 1: zmin = round(zmin,idec-1) ; zmax = round(zmax,idec-1)

    zmin = zmin*rmagn
    zmax = zmax*rmagn

    zdf = (zmax - zmin)/ndf


    while zmax - zdf >= zmax0 and zmin + zdf <= zmin0:
        zmax = zmax - zdf
        zmin = zmin + zdf

    if abs(zmin) < zmax: zmax = abs(zmin)
    if abs(zmin) > zmax: zmin = -zmax

    # Might divide zdf by 2 of zmax and zmin really decreased...
    rn1 = (zmax-zmin)/zdf
    nn = int(round(float(ndf)/rn1,0))
    zdf = zdf/nn


    fact = 10**(-(int(math.log10(zdf))-1))
    zdf = round(zdf*fact,0)
    zdf = zdf/fact




    return [ zmin, zmax, zdf ]





def find_index_from_value( val, VX ):
    if val > nmp.max(VX) or val < nmp.min(VX):
        print 'ERROR: find_index_from_value.barakuda_tool => value outside range of Vector!'
        print VX[:] ; print ' => value =', val
        sys.exit(0)
    jval = -1; jj = 0 ; lfound = False
    while not lfound:
        if VX[jj] <= val and VX[jj + 1] > val:
            jval = jj+1; lfound = True
        jj = jj+1
    return jval


def drown(X, mask, k_ew=-1, nb_max_inc=5, nb_smooth=5):
    #
    #
    ##############################################################################
    #
    #  PURPOSE : fill continental areas of field X (defined by mask=0)
    #  -------   using nearest surrounding sea points (defined by mask=1)
    #            field X is absoluletly unchanged on mask=1 points
    #
    #  k_ew :  east-west periodicity on the input file/grid
    #          k_ew = -1  --> no periodicity
    #          k_ew >= 0  --> periodicity with overlap of k_ew points
    # 
    #  X    :  treated array                             (2D array)
    #  mask :  land-sea mask    INTEGER !!!!             (2D array)
    #
    # Optional:
    #  * nb_smooth : number of times the smoother is applied on masked region (mask=0)
    #                => default: nb_smooth = 50
    #
    #
    #                       Author : Laurent BRODEAU, 2007, as part of SOSIE
    #                                ported to python November 2013
    #
    ##############################################################################

    cmesg = 'ERROR, barakuda_tool.py => drown :'
    
    rr = 0.707

    nbdim = len(nmp.shape(X))

    if nbdim > 3 or nbdim <2:
        print cmesg+' size of data array is wrong!!!'; sys.exit(0)


    nt = 1
    l_record = False    
    if nbdim == 3: l_record = True
    

    if l_record:
        if nmp.shape(X[0,:,:]) != nmp.shape(mask):
            print cmesg+' size of data and mask do not match!!!'; sys.exit(0)
        [nt, nj,ni] = nmp.shape(X)
    else:
        if nmp.shape(X) != nmp.shape(mask):
            print cmesg+' size of data and mask do not match!!!'; sys.exit(0)
        [nj,ni] = nmp.shape(X)


    if nmp.sum(mask) == 0 :
        print 'The mask does not have sea points! Skipping drown!'
        return


    Xtemp = nmp.zeros(nj*ni) ; Xtemp.shape = [nj,ni]


    for jt in range(nt):

        if l_record:
            print '  DROWN (barakuda_tool.py) => treating record '+str(jt+1)
            Xtemp[:,:] = X[jt,:,:]
        else:
            Xtemp[:,:] = X[:,:]

        maskv = nmp.zeros(nj*ni, dtype=nmp.int) ; maskv.shape = [nj,ni] 
        dold = nmp.zeros(nj*ni) ; dold.shape = [nj,ni]
        xtmp = nmp.zeros(nj*ni) ; xtmp.shape = [nj,ni]
        mask_coast = nmp.zeros(nj*ni) ; mask_coast.shape = [nj,ni]
    
        jinc = 0
        
        maskv[:,:] = mask[:,:]
    
        for jinc in range(1,nb_max_inc+1):
    
            dold[:,:] = Xtemp[:,:]
    
            # Building mask of the coast-line (belonging to land points)
            mask_coast[:,:] = 0
            
            mask_coast[1:-1,1:-1] = (maskv[1:-1,2:] + maskv[2:,1:-1] + maskv[1:-1,:-2] + maskv[:-2,1:-1])*(-(maskv[1:-1,1:-1]-1))
    
            if k_ew >= 0:
                # Left LBC:
                mask_coast[1:-1,0]    = (maskv[1:-1,1]    + maskv[2:,0]    + maskv[1:-1,ni-1-k_ew] + maskv[:-2,0]   )*(-(maskv[1:-1,0]   -1))
                # Right LBC:
                mask_coast[1:-1,ni-1] = (maskv[1:-1,k_ew] + maskv[2:,ni-1] + maskv[1:-1,ni-2]      + maskv[:-2,ni-1])*(-(maskv[1:-1,ni-1]-1))
    
            idx_coast = nmp.where(mask_coast[:,:] > 0)
            #mask_coast[:,:] = 0
            #mask_coast[idx_coast] = 1
    
    
    
    
    
            # Extrapolating sea values on that coast line:
    
            (idx_j_land,idx_i_land) = idx_coast
    
            ic = 0
            for jj in idx_j_land:
                ji = idx_i_land[ic]
    
                if ji == 0 and k_ew >= 0:
                    Xtemp[jj,0] = 1./(maskv[jj,1]+maskv[jj+1,0]+maskv[jj,ni-1-k_ew]+maskv[jj-1,0]+
                                   rr*maskv[jj+1,1]+rr*maskv[jj+1,ni-1-k_ew]+rr*maskv[jj-1,ni-1-k_ew]+rr*maskv[jj-1,1])*(
                        maskv[jj,1]*dold[jj,1] + maskv[jj+1,0]*dold[jj+1,0] +
                        maskv[jj,ni-1-k_ew]*dold[jj,ni-1-k_ew] + maskv[jj-1,0]*dold[jj-1,0] +
                        rr*maskv[jj+1,1]*dold[jj+1,1] + rr*maskv[jj+1,ni-1-k_ew]*dold[jj+1,ni-1-k_ew] +
                        rr*maskv[jj-1,ni-1-k_ew]*dold[jj-1,ni-1-k_ew] + rr*maskv[jj-1,1]*dold[jj-1,1]  )
                    
                elif ji == ni-1 and k_ew >= 0:
                    Xtemp[jj,ni-1] = 1./(maskv[jj,k_ew]+maskv[jj+1,ni-1]+maskv[jj,ni-2]+maskv[jj-1,ni-1]+
                                   rr*maskv[jj+1,k_ew]+rr*maskv[jj+1,ni-2]+rr*maskv[jj-1,ni-2]+rr*maskv[jj-1,k_ew])*(
                        maskv[jj,k_ew]*dold[jj,k_ew] + maskv[jj+1,ni-1]*dold[jj+1,ni-1] +
                        maskv[jj,ni-2]*dold[jj,ni-2] + maskv[jj-1,ni-1]*dold[jj-1,ni-1] +
                        rr*maskv[jj+1,k_ew]*dold[jj+1,k_ew] + rr*maskv[jj+1,ni-2]*dold[jj+1,ni-2] +
                        rr*maskv[jj-1,ni-2]*dold[jj-1,ni-2] + rr*maskv[jj-1,k_ew]*dold[jj-1,k_ew]  )
                
                else:
                    Xtemp[jj,ji] = 1./(maskv[jj,ji+1]+maskv[jj+1,ji]+maskv[jj,ji-1]+maskv[jj-1,ji]+
                                   rr*maskv[jj+1,ji+1]+rr*maskv[jj+1,ji-1]+rr*maskv[jj-1,ji-1]+rr*maskv[jj-1,ji+1])*(
                        maskv[jj,ji+1]*dold[jj,ji+1] + maskv[jj+1,ji]*dold[jj+1,ji] +
                        maskv[jj,ji-1]*dold[jj,ji-1] + maskv[jj-1,ji]*dold[jj-1,ji] +
                        rr*maskv[jj+1,ji+1]*dold[jj+1,ji+1] + rr*maskv[jj+1,ji-1]*dold[jj+1,ji-1] +
                        rr*maskv[jj-1,ji-1]*dold[jj-1,ji-1] + rr*maskv[jj-1,ji+1]*dold[jj-1,ji+1]  )
                
                ic = ic+1
    
            # Loosing land for next iteration:
            maskv[idx_coast] = 1
    
    
        # Smoothing the what's been done on land:
        if nb_smooth >= 1:
            
            dold[:,:] = Xtemp[:,:]
            
            for kk in range(nb_smooth):
    
                xtmp[:,:] = Xtemp[:,:]
            
                Xtemp[1:-1,1:-1] = 0.35*xtmp[1:-1,1:-1] + 0.65*0.25*( xtmp[1:-1,2:] + xtmp[2:,1:-1] + xtmp[1:-1,:-2] + xtmp[:-2,1:-1] )
                
                if k_ew != -1:   # we can use east-west periodicity
                    Xtemp[1:-1,0] = 0.35*xtmp[1:-1,0] + 0.65*0.25*( xtmp[1:-1,1] + xtmp[2:,1] + xtmp[1:-1,ni-1-k_ew] + xtmp[:-2,1] )
                    
                    Xtemp[1:-1,ni-1] = 0.35*xtmp[1:-1,ni-1] + 0.65*0.25*( xtmp[1:-1,k_ew] + xtmp[2:,ni-1] + xtmp[1:-1,ni-2] + xtmp[:-2,ni-1] )
        
        
            Xtemp[1:-1,:] = mask[1:-1,:]*dold[1:-1,:] - (mask[1:-1,:]-1)*Xtemp[1:-1,:]
    
    
        del maskv, dold, mask_coast, xtmp
    
        if l_record:
            X[jt,:,:] = Xtemp[:,:]
        else:
            X[:,:]    = Xtemp[:,:]

        Xtemp[:,:] = 0.

    # loop on nt over

    del Xtemp

    return





def extend_domain(ZZ, ext_deg):
    #
    # IN:
    # ===
    # ZZ      : array to extend in longitude, 2D field or 1D longitude vector
    # ext_deg : zonal extension in degrees...
    #
    # OUT:
    # ====
    # ZZx     : zonally-extended array
    #
    #
    #
    vdim = ZZ.shape
    #
    ndim = len(vdim)
    #
    if ndim < 1 or ndim > 3:
        print 'extend_conf.py: ERROR we only treat 1D or 2D arrays...'; sys.exit(0)
        #
    #print vdim
    #
    if ndim == 3:
        [ nz , ny , nx ] = vdim
        #print 'nx, ny, nz = ', nx, ny, nz
    #
    if ndim == 2:
        [ ny , nx ] = vdim
        #print 'nx, ny = ', nx, ny
    #
    if ndim == 1:
        [ nx ] = vdim
        #print 'nx = ', nx
    #
    #
    #
    nb_ext = int(nx/360.*ext_deg) ; #print 'nb_ext =', nb_ext, '\n'
    nx_ext = nx + nb_ext ; #print 'nx_ext =', nx_ext
    #
    #
    if ndim == 3:
        ZZx  = nmp.zeros(nx_ext*ny*nz) ;  ZZx.shape = [nz, ny, nx_ext]
        #
        for jx in range(nx):
            ZZx[:,:,jx] = ZZ[:,:,jx]
        #
        for jx in range(nx, nx_ext):
            ZZx[:,:,jx] = ZZ[:,:,jx-nx]
        #
    #
    if ndim == 2:
        ZZx  = nmp.zeros(nx_ext*ny) ;  ZZx.shape = [ny, nx_ext]
        #
        for jx in range(nx):
            ZZx[:,jx] = ZZ[:,jx]
        #
        for jx in range(nx, nx_ext):
            ZZx[:,jx] = ZZ[:,jx-nx]
        #
    #
    if ndim == 1:
        ZZx  = nmp.zeros(nx_ext) ;  ZZx.shape = [nx_ext];
        #
        for jx in range(nx):
            ZZx[jx]     = ZZ[jx]
        #
        for jx in range(nx,nx_ext):
            ZZx[jx]     = ZZ[jx-nx] + 360.
        #
    #
    return ZZx



def mk_zonal(XF, XMSK, rmin=-1.E-6, rmax=1.E6):
    
    [ ny , nx ] = XF.shape

    VZ = nmp.zeros(ny) ; VZ.shape = [ ny ]

    # Zonally-averaging:
    for jy in range(ny):
        cpt = 0
        for jx in range(nx):
            if XF[jy,jx] > rmin and XF[jy,jx] < rmax:
                if XMSK[jy,jx] == 1:
                    cpt = cpt + 1 ;  VZ[jy] = VZ[jy] + XF[jy,jx]
        #
        if cpt > 0 : VZ[jy] = VZ[jy]/cpt
    return VZ






def read_box_coordinates_in_ascii(cf):
    chck4f(cf)

    f = open(cf, 'r')
    cread_lines = f.readlines()
    f.close()

    vboxes = [] ; vi1    = [] ; vj1    = [] ; vi2    = [] ; vj2    = []
    leof = False
    jl   = -1
    
    while not leof:
        jl = jl + 1
        ll = cread_lines[jl]
        ls = ll.split()

        c1 = ls[0] ; c1 = c1[0]

        if c1 != '#' and ls[0] != 'EOF':
            vboxes.append(ls[0])
            vi1.append(int(ls[1]))
            vj1.append(int(ls[2]))
            vi2.append(int(ls[3]))
            vj2.append(int(ls[4]))
            
        if ls[0] == 'EOF': leof = True


    return vboxes, vi1, vj1, vi2, vj2
