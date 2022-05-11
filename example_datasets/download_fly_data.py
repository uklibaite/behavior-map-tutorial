#!/bin/python3

import os


links = ['https://www.dropbox.com/s/5ig51bg85v7skp6/fly_leap_example_2.h5?dl=1', 
'https://www.dropbox.com/s/t141cqlyn5t1vzw/fly_leap_example_2.mp4?dl=1',
'https://www.dropbox.com/s/gd8r0wmll1guq6q/fly_leap_example.h5?dl=1',
'https://www.dropbox.com/s/6rt56bne56ug65y/fly_leap_example.mp4?dl=1',]
for link in links:
    os.system('curl -L \"%s\" -o %s'%(link, link.split('/')[-1].split('?')[0]))


