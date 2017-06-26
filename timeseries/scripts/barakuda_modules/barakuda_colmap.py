# My own colormaps...

# Check http://matplotlib.org/examples/color/colormaps_reference.html !!!


# Colors:  http://www.pitt.edu/~nisg/cis/web/cgi/rgb.html

# Last Updated: L. Brodeau, January 2013


import numpy as nmp
import matplotlib
matplotlib.use('Agg') ; # important so no DISPLAY is needed!!!
from matplotlib.pylab import cm


ctrl = 0.2 ; # for logarythmic scale in 'pal_eke'


def pal_blk():
    M = nmp.array( [
        [ 0. , 0., 0. ], # black
        [ 0. , 0., 0. ]  # black
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap




def pal_eke():
    M = nmp.array( [
        [ 0.  , 0.0 , 0.2  ], # black
        [ 0.1 , 0.5 , 1.0  ], # blue
        [ 0.2 , 1.0 , 0.0  ], # green
        [ 1.  , 1.0 , 0.0  ], # yellow
        [ 1.  , 0.0 , 0.0  ], # red
        [0.2  , 0.27, 0.07 ] # brown
        ] )
    my_cmap = __build_colormap__(M, log_ctrl=ctrl)
    return my_cmap


def pal_bathy():
    M = nmp.array( [
        [ 0.0 , 0.0 , 0.4 ], # dark blue
        [ 0.1 , 0.5 , 1.0  ], # blue
        [ 0.2 , 1.0 , 0.0  ], # green
        [ 1.  , 1.0 , 0.0  ], # yellow
        [ 1.  , 0.0 , 0.0  ], # red
        [0.2  , 0.27, 0.07 ] # brown
        ] )
    my_cmap = __build_colormap__(M, log_ctrl=ctrl)
    return my_cmap



def pal_mld():
    M = nmp.array( [
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.1 , 0.5 , 1.0 ], # light blue
        [ 0.13, 0.54, 0.13], # dark green
        [ 0.2 , 1.0 , 0.0 ], # light green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark redish brown
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_mld_r():
    M = nmp.array( [
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.1 , 0.5 , 1.0 ], # light blue
        [ 0.13, 0.54, 0.13], # dark green
        [ 0.2 , 1.0 , 0.0 ], # light green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark redish brown
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap



def pal_jetblanc():
    M = nmp.array( [
        [ 0.6 , 0.0 , 0.8 ], # violet
        [ 0.0 , 0.0 , 0.4 ], # dark blue
        [ 0.1 , 0.5 , 1.0 ], # light blue
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ]  # dark redish brown
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap


def pal_jetblanc_r():
    M = nmp.array( [
        [ 0.6 , 0.0 , 0.8 ], # violet
        [ 0.0 , 0.0 , 0.4 ], # dark blue
        [ 0.1 , 0.5 , 1.0 ], # light blue
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark redish brown
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap



def pal_amoc():
    M = nmp.array( [
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 1.0 , 1.0 , 1.0 ], # white
        [0.68 , 0.98, 0.98], # light blue
        [ 0.0 , 0.0 , 0.95], # dark blue
        [ 0.2 , 1.0 , 0.0 ], # green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark read
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap


#        [ 0.2 , 1.0 , 0.0 ], # green

def pal_sst():
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 0. , 0.2 , 0.99], # dark blue
        [0.68 , 0.98, 0.98], # light blue
        [ 0.13, 0.54, 0.13], # dark green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark read
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap


def pal_sst_r():
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 0. , 0.2 , 0.99], # dark blue
        [0.68 , 0.98, 0.98], # light blue
        [ 0.13, 0.54, 0.13], # dark green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark read
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap


def pal_sst0():
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 0.0 , 0.0 , 0.95], # dark blue
        [0.68 , 0.98, 0.98], # light blue
        [46./255., 203./255., 35./255.], # green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark read
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

#        [ 253./255., 238./255., 1. ], # really pale pink
#        [ 0.2 , 1.0 , 0.0 ], # green

def pal_sst0_r():
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 0.0 , 0.0 , 0.95], # dark blue
        [0.68 , 0.98, 0.98], # light blue
        [46./255., 203./255., 35./255.], # green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark read
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap





def pal_std():
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.8 , 0.8 , 0.8 ], # grey
        [ 0.4 , 0.0 , 0.6 ], # violet
        [ 0.0 , 0.0 , 0.95], # dark blue
        [0.68 , 0.98, 0.98], # light blue
        [ 0.13, 0.54, 0.13], # dark green
        [ 0.2 , 1.0 , 0.0 ], # green
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ] # dark read
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_ice():
    M = nmp.array( [
        [  0. , 0.  , 0.3 ], # dark blue
        [  0. , 0. ,  1.0 ], # blue
        [ 0.6 , 0.6 , 0.8 ], # light grey
        [ 1.0 , 1.0 , 1.0 ]  # white
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap


def pal_rms():
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ],
        [ 0.1 , 0.5 , 1.0 ],
        [ 0.2 , 1.0 , 0.0 ],
        [ 1.0 , 1.0 , 0.0 ],
        [ 1.0 , 0.0 , 0.0 ],
        [ 0.2 , 0.3 , 0.1 ]
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap



def pal_sigtr():
    #[ 1.0 , 0.4 , 1.0 ], # violet pinkish
    #[ 1.0 , 1.0 , 1.0 ], # white
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.0 , 0.8 , 1.0 ], #light blue
        [ 0.1 , 0.5 , 1.0 ], #light blue
        [ 0.0 , 0.0 , 0.4 ], # blue
        [ 0.0 , 0.4 , 0.0 ], # dark green
        [ 0.1 , 1.0 , 0.0 ], # green
        [ 0.4 , 1.0 , 0.0 ], # vert pomme
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.4 , 0.0 ], # orange
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.6 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ]  # dark red
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap


def pal_sigtr_r():
    #[ 1.0 , 0.4 , 1.0 ], # violet pinkish
    #[ 1.0 , 1.0 , 1.0 ], # white
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 0.0 , 0.8 , 1.0 ], #light blue
        [ 0.1 , 0.5 , 1.0 ], #light blue
        [ 0.0 , 0.0 , 0.4 ], # blue
        [ 0.0 , 0.4 , 0.0 ], # dark green
        [ 0.1 , 1.0 , 0.0 ], # green
        [ 0.4 , 1.0 , 0.0 ], # vert pomme
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 1.0 , 0.4 , 0.0 ], # orange
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 0.6 , 0.0 , 0.0 ], # red
        [ 0.2 , 0.3 , 0.1 ]  # dark red
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap


def pal_bbr():
    M = nmp.array( [
        [ 0.  , 0. , 0.2 ],
        [ 0.  , 0. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 0. , 0.  ],
        [ 0.6 , 0. , 0.  ]
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_bbr_r():
    M = nmp.array( [
        [ 0.  , 0. , 0.2 ],
        [ 0.  , 0. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 0. , 0.  ],
        [ 0.6 , 0. , 0.  ]
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap




def pal_bbr2():
    M = nmp.array( [
        [ 0.  , 1. , 1.  ], # cyan
        [ 0.  , 0. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 0. , 0.  ],
        [ 1.  , 1. , 0.  ]  # jaune
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_bbr2_r():
    M = nmp.array( [
        [ 0.  , 1. , 1.  ], # cyan
        [ 0.  , 0. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 0. , 0.  ],
        [ 1.  , 1. , 0.  ]  # jaune
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap




def pal_bbr0():
    M = nmp.array( [
        [ 0.  , 1. , 1.  ], # cyan
        [ 0.  , 0. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 0. , 0.  ],
        [ 1.  , 1. , 0.  ]  # jaune
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap



def pal_bbr_cold():
    M = nmp.array( [
        [ 0.  , 1. , 1.  ], # cyan
        [ 0.  , 0. , 1.  ],
        [ 19./255.  , 7./255. , 129./255  ], # dark blue
        [ .1  , .1 , .9  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 0.6 , 0.6  ],
        [ 1.  , 0.3 , 0.3  ]
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_bbr_warm():
    M = nmp.array( [
        [ 0.3  , 0.3 , 1.  ],
        [ 0.6  , 0.6 , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 0.9  , 0.1 , 0.1  ],
        [ 0.7  , 0. , 0.  ], # Dark red
        [ 1.  , 0.2 , 0.  ],
        [ 1.  , 1. , 0.  ]  # jaune
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

#        [ 19./255.  , 7./255. , 129./255  ], # dark blue
#         [ 0.  , 1. , 1.  ], # cyan
#


def pal_bbr0_r():
    M = nmp.array( [
        [ 0.  , 1. , 1.  ], # cyan
        [ 0.  , 0. , 1.  ],
        [ 1.  , 1. , 1.  ],
        [ 1.  , 0. , 0.  ],
        [ 1.  , 1. , 0.  ]  # jaune
        ] )
    my_cmap = __build_colormap__(M[::-1,:])
    return my_cmap







def pal_cold0():
    M = nmp.array( [
        [ 177./255.  , 250./255. , 122./255. ],   # greenish
        [ 0.  , 1. , 1.  ], # cyan
        [ 7./255.  , 11./255. , 122./255. ], # dark blue
        [ 0.  , 0. , 1.  ], # true blue
        [ 177./255.  , 189./255. , 250./255. ], # light blue
        [ 1.  , 1. , 1.  ],
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap
# #        [ 177./255.  , 250./255. , 122./255. ],   # greenish



def pal_warm0():
    M = nmp.array( [
        [ 1.  , 1. , 1.  ],
        [ 255./255.  , 254./255. , 198./255.  ], # very light yellow
        [ 1.  , 1. , 0.  ],  # yellow
        [ 244./255.  , 78./255. , 255./255.  ], # pink
        [ 1.  , 0. , 0.  ], # true red
        [ 139./255.  , 5./255. , 5./255.  ] # dark red
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap
#        [ 247./255.  , 150./255. , 176./255.  ], # light red






def pal_graylb():
    M = nmp.array( [
        [ 1.  , 1. , 1. ],
        [ 0.1  , 0.1 , 0.1 ]
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_graylb_r():
    M = nmp.array( [
        [ 0.  , 0. , 0. ],
        [ 1.  , 1. , 1. ]
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_graylb2():
    M = nmp.array( [
        [ 0.6  , 0.6 , 0.6 ],
        [ 1.  , 1. , 1. ]
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap



def pal_sigma():
    M = nmp.array( [
        [ 1.0 , 1.0 , 1.0 ], # white
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 0.2 , 1.0 , 0.0 ], # green
        [ 0.1 , 0.5 , 1.0 ], # light blue
        [ 0.0 , 0.0 , 0.4 ], # dark blue
        [ 0.6 , 0.0 , 0.8 ]  # violet
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_sigma0():
    M = nmp.array( [
        [ 0.2 , 0.3 , 0.1 ], # dark redish brown
        [ 1.0 , 0.0 , 0.0 ], # red
        [ 1.0 , 1.0 , 0.0 ], # yellow
        [ 0.2 , 1.0 , 0.0 ], # green
        [ 0.1 , 0.5 , 1.0 ], # light blue
        [ 0.0 , 0.0 , 0.4 ], # dark blue
        [ 0.6 , 0.0 , 0.8 ], # violet
        [ 1.0 , 1.0 , 1.0 ]  # white
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap

def pal_mask():
    M = nmp.array( [
        [ 0.5 , 0.5 , 0.5 ], # gray
        [ 0.5 , 0.5 , 0.5 ]  # gray
        ] )
    my_cmap = __build_colormap__(M)
    return my_cmap




#=======================================================================



def chose_palette(cname):

    if cname == 'jet'   : palette = cm.jet
    if cname == 'mld'   : palette = pal_mld()
    if cname == 'mld_r' : palette = pal_mld_r()
    if cname == 'rms'   : palette = pal_rms()
    if cname == 'bbr'   : palette = pal_bbr()
    if cname == 'bbr_r' : palette = pal_bbr_r()
    if cname == 'bbr2'  : palette = pal_bbr2()
    if cname == 'bbr2_r': palette = pal_bbr2_r()
    if cname == 'bbr0'  : palette = pal_bbr0()
    if cname == 'bbr0_r': palette = pal_bbr0_r()
    if cname == 'bbr_warm'  : palette = pal_bbr_warm()
    if cname == 'bbr_cold'  : palette = pal_bbr_cold()
    if cname == 'cold0'  : palette = pal_cold0()
    if cname == 'warm0'  : palette = pal_warm0()
    if cname == 'ice'   : palette = pal_ice()
    if cname == 'sst'   : palette = pal_sst()
    if cname == 'sst_r' : palette = pal_sst_r()
    if cname == 'sst0'  : palette = pal_sst0()
    if cname == 'sst0_r': palette = pal_sst0_r()
    if cname == 'eke'   : palette = pal_eke()
    if cname == 'bathy' : palette = pal_bathy()
    if cname == 'jetblanc' : palette = pal_jetblanc()
    if cname == 'jetblanc_r' : palette = pal_jetblanc_r()
    if cname == 'std'  : palette = pal_std()
    if cname == 'sigtr'  : palette = pal_sigtr()
    if cname == 'sigtr_r': palette = pal_sigtr_r()
    if cname == 'amoc': palette = pal_amoc()
    if cname == 'sigma': palette = pal_sigma()
    if cname == 'sigma0': palette = pal_sigma0()
    if cname == 'graylb': palette = pal_graylb()
    if cname == 'graylb_r': palette = pal_graylb_r()
    if cname == 'graylb2': palette = pal_graylb2()
    if cname == 'mask': palette = pal_mask()
    return palette







# ===== local functions ======


def __build_colormap__(MC, log_ctrl=0):

    [ nc, n3 ] = nmp.shape(MC)

    # Make x vector :
    x =[]
    for i in range(nc): x.append(255.*float(i)/((nc-1)*255.0))
    x = nmp.array(x)
    if log_ctrl > 0: x = nmp.log(x + log_ctrl)
    rr = x[nc-1] ; x  = x/rr

    y =nmp.zeros(nc)
    for i in range(nc): y[i] = x[nc-1-i]

    x = 1 - y ; rr = x[nc-1] ; x  = x/rr

    red  = [] ; blue = [] ; green = []

    for i in range(nc):
        red.append  ([x[i],MC[i,0],MC[i,0]])
        green.append([x[i],MC[i,1],MC[i,1]])
        blue.append ([x[i],MC[i,2],MC[i,2]])

    cdict = {'red':red, 'green':green, 'blue':blue}
    my_cm = matplotlib.colors.LinearSegmentedColormap('my_colormap',cdict,256)

    return my_cm
