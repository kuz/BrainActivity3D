
import numpy as np
import pylab as pl
from sklearn.decomposition import FastICA
from numpy import *
f = open("201305161823-KT-mental-3-240.csv").readlines()
lines = [map(float, ln.split(',')) for ln in f]
#lines = array(lines)
lines = np.asarray(lines)
lines.shape
lines = delete(lines, s_[14:16], axis=1) #delete last column
lines.shape

ica = FastICA()
X = lines
S_ = ica.fit(X).transform(X)  # Get the estimated sources
S_.shape
A_ = ica.mixing_  # Get estimated mixing matrix
A_.shape

assert np.allclose(X, np.dot(S_, A_.T) + ica.mean_)
pl.figure()
pl.subplot(2, 1, 1)
pl.plot(X)
pl.title('Observations (mixed signal)')
pl.subplot(2, 1, 2)
pl.plot(S_)
pl.title('ICA estimated sources')
#pl.subplots_adjust(0.09, 0.04, 0.94, 0.94, 0.26, 0.36)
pl.show()

