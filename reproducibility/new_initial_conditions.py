import numpy as np
import argparse
import sys
import pygrib
import glob



'''
Program to create new initial conditions from existing ones. Perturbs the temperature at model-level
30 at a random gridpoint by 0.1. Requires the ICMSH***INIT file of the existing IC
'''


#This number specifies a gridpoint where the temperature is perturbed. For T255 resolution this
#can be any number between 1 and 256*512 = 131072. Make sure to specify a different number
#for each new set of initial conditions you want to create.
num = 100


#Amount to perturb by
pert = 0.1



#num should be even, because of how spectral wavenumbers are packed!
if num % 2 == 1:
    sys.exit("Error: num must be even!")
else:   pass

    

#Specifying the directory where the IC lies and where you want the new one to be output
ini_data_dir = '/network/aopp/preds0/pred/users/strommen/Data/InitialConditions'
out_dir = '/network/aopp/preds0/pred/users/strommen/Data/InitialConditions'

#The actual ICMSH file to be perturbed. expname_old is name of existing experiment, 
#expname_new is the name of the new initial condition file experiment
expname_old = 'ECE3'
expname_new = 'TEST'
file_in = '%s/ICMSH%sINIT' % (ini_data_dir, expname_old)



#Reading the original IC file
grbs_in = pygrib.open(file_in)
messages_in=grbs_in.read()
grbs_in.close() 


#Creating a new file where we'll store the perturbed conditions
grb_out=open('%s/ICMSH%sINIT' % (out_dir, expname_new),'wb')


#Preventing expansion onto regular grid to allow us to edit the field and then save it again
for message in messages_in:
    message.expand_grid(False)


#Actually doing the perturbation
for msg in messages_in:

    if msg['shortName'] == 't' and msg['level'] == 30:
        t=msg['values']
        print "Perturbing gridpoint number %d by %s..." % (num, pert)
        t[num] = t[num] + pert       
        msg['values']=t
                
    else:
        pass
    
    grb_out.write(msg.tostring())    

#Closing the file
grb_out.close()    
print "New grib-file saved"    
    



#Testing for success. If the two numbers printed here are different it worked!   
print "Testing if successful:"

grib1 = pygrib.open(file_in)
messages1 = grib1.read()
grib2 = pygrib.open('%s/ICMSH%sINIT' % (out_dir, expname_new))
messages2 = grib2.read()
grib1.close()
grib2.close()

for msg in messages1:        
    if msg['shortName'] == 't' and msg['level'] == 30:
        print msg['values'][num]
    else:
        pass
        
for msg in messages2:        
    if msg['shortName'] == 't' and msg['level'] == 30:
        print msg['values'][num]
    else:
        pass         


#End of script
           

