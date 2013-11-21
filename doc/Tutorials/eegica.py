# -*- coding: utf-8 -*-
# <nbformat>3.0</nbformat>

# <codecell>

import numpy as np
import pylab as pl
from sklearn.decomposition import FastICA
from numpy import *


# <codecell>

f = open("201305161823-KT-mental-3-240.csv").readlines()
lines = [map(float, ln.split(',')) for ln in f]
#lines = array(lines)
lines = np.asarray(lines)
lines.shape

# <codecell>

lines = np.delete(lines, [14,15,16], axis=1) #delete last 2 columns
lines.shape

# <codecell>

ica = FastICA(2)
X = lines
ica.fit(X)
S_ = ica.transform(X)  # Get the estimated sources
S_.shape
A_ = ica.mixing_  # Get estimated mixing matrix
print A_.shape
print S_.shape
print X.shape
print ica.mean_

# <codecell>

A_
#np.set_printoptions(suppress=True, precision=3)
#ica.mixing_

# <codecell>

#std(ica.mixing_[:,:],axis=0)

# <codecell>

FastICA??

