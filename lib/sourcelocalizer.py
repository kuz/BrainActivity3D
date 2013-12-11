"""

Implementation of Source Localization
    * Estimate electrode contributions using ica
    * Optimize for (x, y, z, k), where k is coefficient to convert ICA's output to the distance

"""

from sklearn.decomposition import FastICA
from scipy.optimize import minimize
from sklearn.decomposition import PCA
import operator
import time
import random

class SourceLocalizer:

    data = None
    epoc = None
    mixing_matrix = None
    electrode_data = []
    number_of_sources = None
    last_source_locations = {}

    def __init__(self, epoc):
        self.epoc = epoc

    def set_data(self, data):
        self.data = data
        self.number_of_sources = self.estimate_sources();

    def ica(self):
        '''
        Perform ICA on the data
            source_matrix -- rows are sources, columns are time points, values are ?
            mixing_matrix -- rows are electrodes, columns are source, values are contributions of the electrode to the source
        '''
        ica = FastICA(self.number_of_sources)
        ica.fit(self.data)
        self.mixing_matrix = ica.mixing_  # estimated mixing matrix

    def optimize(self, source):
        '''
        Input:
            source - integer, id of the source
        Return
            (x, y, z, k)
        '''
        self.electrode_data = []
        for i,coordinate in enumerate(self.epoc.coordinates):
            self.electrode_data.append({'position':coordinate[0], 'contribution': self.mixing_matrix[i][source]}) 

        result = minimize(self.error, self.last_source_locations.get(source, [0, 0, 0, 1]), method='Nelder-Mead')     
        return result.x

    def error(self, configuration):
        source_pos = configuration[0:3]
        k = configuration[3]
        alpha = 0.3
        s = 0
        for electrode in self.electrode_data:
            s += (electrode['contribution'] - self.contribution_estimate(source_pos, electrode['position'], k))**2 + alpha*(sum((source_pos - electrode['position'])**2) + 1)
        return s

    def contribution_estimate(self, source_pos, electrode_pos, k):
        return k / (sum((source_pos - electrode_pos)**2) + 1)

    def localize(self, source):   
        self.ica()
        (x, y, z, k) = self.optimize(source)
        self.last_source_locations[source] = [x, y, z, k]
        return [x, y, z]

    def estimate_sources(self):
        pca = PCA()
        pca.fit(self.data)
        return list(pca.explained_variance_ratio_ > 0.1).count(True)
