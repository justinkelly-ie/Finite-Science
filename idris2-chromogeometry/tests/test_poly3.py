from fractions import Fraction
import random

def spread(metric, x1, y1, x2, y2, x3, y3):
    def q(m, a, b, c, d):
        dx = c - a; dy = d - b
        if m == 'B': return dx*dx + dy*dy
        if m == 'R': return dx*dx - dy*dy
        if m == 'G': return dy*dy - dx*dx
    q1 = q(metric, x1, y1, x2, y2)
    q2 = q(metric, x2, y2, x3, y3)
    q3 = q(metric, x3, y3, x1, y1)
    arch = 2*(q1*q1 + q2*q2 + q3*q3) - (q1 + q2 + q3)**2
    return arch, 4 * q1 * q3

for _ in range(2):
    x1, y1 = random.randint(-10,10), random.randint(-10,10)
    x2, y2 = random.randint(-10,10), random.randint(-10,10)
    x3, y3 = random.randint(-10,10), random.randint(-10,10)
    
    nb, db = spread('B', x1,y1,x2,y2,x3,y3)
    nr, dr = spread('R', x1,y1,x2,y2,x3,y3)
    ng, dg = spread('G', x1,y1,x2,y2,x3,y3)
    if db*dr*dg == 0: continue
    
    b = Fraction(nb, db)
    r = Fraction(nr, dr)
    g = Fraction(ng, dg)
    
    # Theorem: The sum of the three metric spreads always balances against their product
    # s_b + s_r + s_g = ???
    print("b =", b)
    print("r =", r)
    print("g =", g)
    
    # Let's test combinations of b+r+g and b*r*g
    sum_s = b + r + g
    prod_s = b * r * g
    print("sum =", sum_s)
    print("prod =", prod_s)
    print("sum^2 / prod =", sum_s**2 / prod_s if prod_s != 0 else 0)
    print("2 * sum =", 2 * sum_s)
    print("4 * prod =", 4 * prod_s)
