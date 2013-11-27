'''
http://docs.sympy.org/dev/modules/solvers/solvers.html#systems-of-polynomial-equations
(x-1)^2 + (y-2)^2 = (z*72.0)^2, (x-3)^2 + (y-6)^2 = (z*20.0)^2, (x-5)^2 + (y-3)^2 = (z*56.0)^2
'''

from sympy import solve_poly_system, sympify
from sympy.abc import x, y, z, k
import operator

# Position and contribution data
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

electrode_data = [{'position':[-56.3,  22.3,  7.1], 'contribution': 0.8980},  # F7   (2)
                  {'position':[ 32.1,  39.5, 21.8], 'contribution': 0.2672},  # AF4 (14)
                  {'position':[-47.5, -37.2, 43.6], 'contribution': 0.1928},  # P7   (6)
                  {'position':[ 47.5, -37.2, 43.6], 'contribution': 0.1870}]  # P8   (9)

electrode_data = [{'position':[-56.3,  22.3,  7.1], 'contribution': 0.8374},  # F7   (2)
                  {'position':[ 32.1,  39.5, 21.8], 'contribution': 0.0135},  # AF4 (14)
                  {'position':[-47.5, -37.2, 43.6], 'contribution': 0.0525},  # P7   (6)
                  {'position':[ 47.5, -37.2, 43.6], 'contribution': 0.0829}]  # P8   (9

#electrode_data = sorted(electrode_data, key=lambda k: k['contribution'], reverse=False)
#electrode_data = electrode_data[0:4]

# Equations
equations = []
for electrode in electrode_data:
      equations.append('(x - (%d))^2 + (y - (%d))^2 + (z - (%d))^2 - (%d) * k' % (sympify(electrode['position'][0]),
                                                                                  sympify(electrode['position'][1]),
                                                                                  sympify(electrode['position'][2]),
                                                                                  sympify(electrode['contribution'])))

solutions = solve_poly_system(equations, x, y, z, k)

#for solution in solutions:
#      print [float(x) for x in solution]


best_solution = [99999999999.0]
for solution in solutions:
      solution = [complex(x) for x in solution]
      #if solution[-1] < best_solution[-1]:
      best_solution = solution

print best_solution