'''
http://docs.sympy.org/dev/modules/solvers/solvers.html#systems-of-polynomial-equations
(x-1)^2 + (y-2)^2 = (z*72.0)^2, (x-3)^2 + (y-6)^2 = (z*20.0)^2, (x-5)^2 + (y-3)^2 = (z*56.0)^2
'''

from sympy import solve_poly_system, sympify
from sympy.abc import x, y, z, k

# Position and contribution data
electrode_data = [{'position':[1.0, 2.0], 'contribution': 72.0},
                  {'position':[3.0, 6.0], 'contribution': 20.0},
                  {'position':[5.0, 3.0], 'contribution': 56.0}]

# Equations
equations = []
for electrode in electrode_data:
      equations.append('(x - %d)^2 + (y - %d)^2 - %d * k' % (sympify(electrode['position'][0]),
                                                             sympify(electrode['position'][1]),
                                                             sympify(electrode['contribution'])))

solutions = solve_poly_system(equations, x, y, k)

best_solution = [99999999999.0]
for solution in solutions:
      solution = [float(x) for x in solution]
      if solution[-1] < best_solution[-1]:
            best_solution = solution

print best_solution