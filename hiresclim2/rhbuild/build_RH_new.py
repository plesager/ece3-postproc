
# L. Brodeau, Dec. 2011

import sys
import numpy as nmp
from netCDF4 import Dataset
import string
import os

# Into local "include" :
import mod_ifse as mifse


cv_Q='q'
cv_T='t'
cv_R='r'

if len(sys.argv) != 3:
    print 'Usage: '+sys.argv[0]+' exp_name year'
    sys.exit(0)

# Input:
exp_name = sys.argv[1]
year = sys.argv[2]
OUTDIR0 = os.environ["OUTDIR0"]
INDIR  = OUTDIR0+'/mon/Post_'+year
cf_Q = INDIR+'/'+exp_name+'_'+year+'_q.nc'
cf_T = INDIR+'/'+exp_name+'_'+year+'_t.nc'

# Output:
OUTDIR  = INDIR
cf_R = OUTDIR+'/'+exp_name+'_'+year+'_r.nc'

print 'build_RH_new.py starts ------------------>'
print 'file for Q => '+cf_Q
print 'file for T => '+cf_T
print 'File for RH to create: '+cf_R+'\n'



# Q 3D on pressure levels:
# ~~~~~~~~~~~~~~~~~~~~~~~~
mifse.chck4f(cf_Q)

f_Q_in = Dataset(cf_Q)

vlev     = f_Q_in.variables['lev'][:]
cunt_lev = f_Q_in.variables['lev'].units

nk = len(vlev)

print str(nk)+' pressure levels:'
print vlev, '\n'

if max(vlev) != 100000.0:
    print 'PROBLEM: levels do not really look like pressure levels in Pa...'
    sys.exit(0)



vlon     = f_Q_in.variables['lon'][:]
clnm_lon = f_Q_in.variables['lon'].long_name ;
cunt_lon = f_Q_in.variables['lon'].units
print 'LONGITUDE: ', cunt_lon

vlat     = f_Q_in.variables['lat'][:]
clnm_lat = f_Q_in.variables['lat'].long_name ;
cunt_lat = f_Q_in.variables['lat'].units
print 'LATGITUDE: ', cunt_lat

# Extracting time 1D array:
vtime     = f_Q_in.variables['time'][:] ; cunt_time = f_Q_in.variables['time'].units
print 'TIME: ', cunt_time, '\n'

# Extracting a variable, ex: "t" the 3D+T field of temperature:
xQ     = f_Q_in.variables[cv_Q][:,:,:,:]
cunt_Q = f_Q_in.variables[cv_Q].units
#code_Q = f_Q_in.variables[cv_Q].code
#ctab_Q = f_Q_in.variables[cv_Q].table
#print cv_Q+': ', cunt_Q, code_Q, ctab_Q, '\n'
f_Q_in.close()


#  T2M
#  ~~~~
mifse.chck4f(cf_T)
f_T_in = Dataset(cf_T)
xT     = f_T_in.variables[cv_T][:,:,:,:]
cunt_T = f_T_in.variables[cv_T].units
f_T_in.close()
print 'Units for T is '+cunt_T






# Checking dimensions
# ~~~~~~~~~~~~~~~~~~~
dim_Q = xQ.shape ; dim_T = xT.shape
if dim_Q != dim_T: print 'Shape problem!!!'; print dim_Q , dim_T

[ nt, nk, nj, ni ] = nmp.shape(xQ)

[ nt, nk, nj, ni ] = dim_Q
print ' Shape of fields is ', ni, nj, nk, nt, '\n'





# Building R
# ~~~~~~~~~~~

xR = nmp.zeros(nt*nk*nj*ni) ; xR.shape = dim_Q

xE     = nmp.zeros(nj*ni) ; xE.shape     = [ nj, ni ]
xE_sat = nmp.zeros(nj*ni) ; xE_sat.shape = [ nj, ni ]
xdum   = nmp.zeros(nj*ni) ; xdum.shape   = [ nj, ni ]



for jt in range(nt):

    #print "\n Time = ", vtime[jt]
    print " Time = ", jt+1
    
    for jk in range(nk):
        pressure = vlev[jk]
        #print ' Level:', jk, ' => pressure: ', pressure

        # Need water vapour pressure "e" from "q" and

        xE[:,:]     = mifse.e_air(xQ[jt,jk,:,:], pressure)

        xE_sat[:,:] = mifse.e_sat(xT[jt,jk,:,:])

        xdum[:,:] = 100.*xE[:,:]/xE_sat[:,:]        

        idxm = nmp.where(xdum[:,:] > 100.); xdum[idxm] = 100.

        xR[jt,jk,:,:] = xdum[:,:]


# Creating output file
# ~~~~~~~~~~~~~~~~~~~~
f_out = Dataset(cf_R, 'w', format='NETCDF3_CLASSIC')

# Dimensions:
f_out.createDimension('lon', ni)
f_out.createDimension('lat', nj)
f_out.createDimension('lev', nk)
f_out.createDimension('time', None)

# Variables
id_lon = f_out.createVariable('lon' ,'f4',('lon', ))
id_lat = f_out.createVariable('lat' ,'f4',('lat', ))
id_lev = f_out.createVariable('lev' ,'f4',('lev', ))
id_tim = f_out.createVariable('time','f4',('time',))
id_R   = f_out.createVariable(cv_R  ,'f4',('time','lev','lat','lon',))

# Attributes

id_tim.units     = cunt_time
id_lev.units     = cunt_lev
id_lat.long_name = clnm_lat ;  id_lat.units = cunt_lat
id_lon.long_name = clnm_lon ;  id_lon.units = cunt_lon
id_R.long_name   = 'Relative Humidity' ; id_R.units = '%' ; id_R.code  = '157' ; id_R.table = '128'
f_out.About      = 'Created by L. Brodeau using Q, T and pressure from pressure levels!'

# Filling variables:
id_lev[:] = vlev[:] ; id_lat[:] = vlat[:] ; id_lon[:] = vlon[:]

for jt in range(nt):
    id_tim[jt]     = vtime[jt]
    id_R[jt,:,:,:] = xR[jt,:,:,:] 

f_out.close()

print cf_R+' is created!'



print 'build_RH_new.py: Bye!'

