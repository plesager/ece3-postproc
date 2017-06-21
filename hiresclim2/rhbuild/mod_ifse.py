# A few Python fuctions
# L. Brodeau June 2012

import os
import sys
import numpy as nmp
import math


rt0 = 273.16
grav  = 9.8          # gravity
Rgas  = 287.04     
Patm  = 101000.    
ctv   = 0.608        # for virtual temperature
eps   = 0.62197      # humidity constant
cte   = 0.622     
kappa = 0.4          # Von Karman's constant
Cp    = 1000.5    
Pi    = 3.141592654 
eps_w = 0.987        # emissivity of water
sigma = 5.67E-8      # Stefan Boltzman constamt
alfa  = 0.066        # Surface albedo over ocean






def chck4f(cf):
    if not os.path.exists(cf):
        print 'File '+cf+' does not exist!'
        sys.exit(0)
    else:
        print '\n Opening file '+cf+'\n'



def Lvap(zsst):
    #
    # INPUT  : zsst => water temperature in [K]
    # OUTPUT : Lvap => Latent Heat of Vaporization [J/Kg/K]
    return ( 2.501 - 0.00237*(zsst - rt0) )*1.E6



def e_sat(rt):
    # vapour pressure at saturation  [Pa]
    # rt      ! temperature (K)
    zrtrt0 = rt/rt0

    return 100*( nmp.power(10.,(10.79574*(1. - rt0/rt) - 5.028*nmp.log10(zrtrt0)     
                 + 1.50475*0.0001*(1. - nmp.power(10.,(-8.2969*(zrtrt0 - 1.))) )
                 + 0.42873*0.001 *(nmp.power(10.,(4.76955*(1. - rt0/rt))) - 1.) + 0.78614 ) ) )



def e_air(q_air, zslp):

    #--------------------------------------------------------------------
    #                  **** Function e_air ****
    #
    # Gives vapour pressure of air from pressure and specific humidity
    #
    #--------------------------------------------------------------------

    diff  = 1.E8
    e_old = q_air*zslp/eps

    while diff > 1.:
        ee = q_air/eps*(zslp - (1. - eps)*e_old)
        diff  = nmp.sum(abs( ee - e_old ))
        e_old = ee

    return ee




def q_sat(zsst, zslp):

    # Specific humidity at saturation
    # -------------------------------

    # Vapour pressure at saturation :
    e_s = 100*(10.^(10.79574*(1-rt0/zsst)-5.028*math.log10(zsst/rt0)  \
                    + 1.50475*10.^(-4)*(1 - 10.^(-8.2969*(zsst/rt0 - 1)) )    \
                   + 0.42873*10.^(-3)*(10.^(4.76955*(1 - rt0/zsst)) - 1) + 0.78614) )

    return eps*e_s/(zslp - (1. - eps)*e_s)



