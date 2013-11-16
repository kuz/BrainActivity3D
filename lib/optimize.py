from numpy import *
from scipy.optimize import minimize, fmin

electrode_data = [{'position':[-32.1,  39.5, 21.8], 'contribution': 6468}, # AF3  (1)
                  {'position':[-56.3,  22.3,  7.1], 'contribution': 5804}, # F7   (2)
                  {'position':[ -8.6,  30.6, 40.7], 'contribution': 5565}, # F3   (3)
                  {'position':[-35.1,  15.6, 35.5], 'contribution': 6078}, # FC5  (4)
                  {'position':[-58.6,  -1.5, 24.8], 'contribution': 6178}, # T7   (5)
                  {'position':[-47.5, -37.2, 43.6], 'contribution': 6869}, # P7   (6)
                  {'position':[-23.2, -60.2, 42.6], 'contribution': 6169}, # O1   (7)
                  {'position':[ 23.2, -60.2, 42.6], 'contribution': 7470}, # O2   (8)
                  {'position':[ 47.5, -37.2, 43.6], 'contribution': 7278}, # P8   (9)
                  {'position':[ 58.6, -1.5,  24.8], 'contribution': 6615}, # T8  (10)
                  {'position':[ 35.1,  15.6, 35.5], 'contribution': 7183}, # FC6 (11)
                  {'position':[  8.6,  30.6, 40.7], 'contribution': 5936}, # F4  (12)
                  {'position':[ 56.3,  22.3,  7.1], 'contribution': 6693}, # F8  (13)
                  {'position':[ 32.1,  39.5, 21.8], 'contribution': 6420}] # AF4 (14)

def contribution_estimate(source_pos, electrode_pos, k):
    return k / (sum((source_pos - electrode_pos)**2) + 1)

def error(configuration):
    source_pos = configuration[0:3]
    k = configuration[3]

    s = 0
    for electrode in electrode_data:
        s += (electrode['contribution'] - contribution_estimate(source_pos, electrode['position'], k))**2
    return s

result = minimize(error, [0, 0, 0, 1], method='Nelder-Mead')
print result