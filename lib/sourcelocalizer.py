"""

Implementation of Source Localization
    * Estimate electrode contibutions using ica
    * Optimize for (x, y, z, k), where k is coefficient to confert ICA's output to the distance

TODO:
    * Check that constant k is same all the time (otherwise the result does not make sense)
    * FastICA ?

"""

import numpy as np
from sklearn.decomposition import FastICA
from scipy.optimize import minimize

class SourceLocalizer:

    data = None
    mixing_matrix = None
    electrode_data = None
    number_of_sources = None

    def __init__(self):
        '''
        Example how to get data variable from file:

            f = open('../data/201305161823-KT-mental-3-240.csv').readlines()
            lines = [map(float, ln.split(',')) for ln in f]
            lines = np.asarray(lines)
            lines = np.delete(lines, [14,15,16], axis=1) # delete last 2 columns

        '''
        self.number_of_sources = self.estimate_sources();

    def set_data(self, data):
        self.data = data

    def ica(self):
        '''
        Perform ICA on the data
            source_matrix -- rows are sources, columns are time points, values are ?
            mixing_matrix -- rows are electodes, columns are source, values are contibutions of the electrode to the source
        '''
        ica = FastICA(self.number_of_sources)
        ica.fit(self.data)
        #self.source_matrix = ica.transform(self.data)  # Get the estimated sources
        #self.source_matrix.shape
        self.mixing_matrix = ica.mixing_  # Get estimated mixing matrix

    def optimize(self, source):
        '''
        Input:
            source - integer, id of the source
        Return
            (x, y, z, k)
        '''
        self.electrode_data = [{'position':[-32.1,  39.5, 21.8], 'contribution': self.mixing_matrix[0][source]}, # AF3  (1)
                               {'position':[-56.3,  22.3,  7.1], 'contribution': self.mixing_matrix[1][source]}, # F7   (2)
                               {'position':[ -8.6,  30.6, 40.7], 'contribution': self.mixing_matrix[2][source]}, # F3   (3)
                               {'position':[-35.1,  15.6, 35.5], 'contribution': self.mixing_matrix[3][source]}, # FC5  (4)
                               {'position':[-58.6,  -1.5, 24.8], 'contribution': self.mixing_matrix[4][source]}, # T7   (5)
                               {'position':[-47.5, -37.2, 43.6], 'contribution': self.mixing_matrix[5][source]}, # P7   (6)
                               {'position':[-23.2, -60.2, 42.6], 'contribution': self.mixing_matrix[6][source]}, # O1   (7)
                               {'position':[ 23.2, -60.2, 42.6], 'contribution': self.mixing_matrix[7][source]}, # O2   (8)
                               {'position':[ 47.5, -37.2, 43.6], 'contribution': self.mixing_matrix[8][source]}, # P8   (9)
                               {'position':[ 58.6, -1.5,  24.8], 'contribution': self.mixing_matrix[9][source]}, # T8  (10)
                               {'position':[ 35.1,  15.6, 35.5], 'contribution': self.mixing_matrix[10][source]}, # FC6 (11)
                               {'position':[  8.6,  30.6, 40.7], 'contribution': self.mixing_matrix[11][source]}, # F4  (12)
                               {'position':[ 56.3,  22.3,  7.1], 'contribution': self.mixing_matrix[12][source]}, # F8  (13)
                               {'position':[ 32.1,  39.5, 21.8], 'contribution': self.mixing_matrix[13][source]}] # AF4 (14)

        result = minimize(self.error, [0, 0, 0, 1], method='Nelder-Mead')
        return result.x

    def error(self, configuration):
        source_pos = configuration[0:3]
        k = configuration[3]

        s = 0
        for electrode in self.electrode_data:
            s += (electrode['contribution'] - self.contribution_estimate(source_pos, electrode['position'], k))**2
        return s

    def contribution_estimate(self, source_pos, electrode_pos, k):
        return k / (sum((source_pos - electrode_pos)**2) + 1)

    def localize(self, source):
        self.ica()
        (x, y, z, k) = self.optimize(source)
        print 'This constant should remain (almost) same: ' + str(k)
        return [x, y, z]

    def estimate_sources(self):
        # TODO: estimate number of sources using PCA
        return 2;


