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
    num = arch
    den = 4 * q1 * q3
    return num, den

from fractions import Fraction
import random

for _ in range(5):
    x1, y1 = random.randint(-10,10), random.randint(-10,10)
    x2, y2 = random.randint(-10,10), random.randint(-10,10)
    x3, y3 = random.randint(-10,10), random.randint(-10,10)
    
    nb, db = spread('B', x1, y1, x2, y2, x3, y3)
    nr, dr = spread('R', x1, y1, x2, y2, x3, y3)
    ng, dg = spread('G', x1, y1, x2, y2, x3, y3)
    if db == 0 or dr == 0 or dg == 0: continue
    sb = Fraction(nb, db)
    sr = Fraction(nr, dr)
    sg = Fraction(ng, dg)
    
    print(f"B={sb} R={sr} G={sg}")
    print("sum =", sb + sr + sg)
    print("prod =", sb * sr * sg)
    print("sum/prod =", (sb+sr+sg) / (sb*sr*sg) if sb*sr*sg != 0 else 0)
    print("sb - sr - sg =", sb - sr - sg)
    print("1/sb + 1/sr + 1/sg =", 1/sb + 1/sr + 1/sg if sb!=0 and sr!=0 and sg!=0 else 0)
    print("-----------")
