#!/bin/python3

import os


links = ["https://www.dropbox.com/s/1wjg0scia1ylpt7/Rat_example.h5?dl=1",
"https://www.dropbox.com/s/ybwcb0cuqr7zcwn/Rat_example.mp4?dl=1"]


for link in links:
    os.system('curl -L \"%s\" -o %s'%(link, link.split('/')[-1].split('?')[0]))


