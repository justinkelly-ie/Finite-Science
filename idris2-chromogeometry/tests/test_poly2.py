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
    num = arch
    den = 4 * q1 * q3
    return Fraction(num, den) if den != 0 else Fraction(0,1)

x1,y1=0,0
x2,y2=1,0
for i in range(1, 4):
    x3, y3 = i, i+1
    b = spread('B', x1,y1,x2,y2,x3,y3)
    r = spread('R', x1,y1,x2,y2,x3,y3)
    g = spread('G', x1,y1,x2,y2,x3,y3)
    print(f"b={b} r={r} g={g}")
    print("1/b+1/r+1/g =", 1/b+1/r+1/g)
    print("1/b-1/r-1/g =", 1/b-1/r-1/g)
    print("1/b + 1/r - 1/g =", 1/b + 1/r - 1/g)
    print("1/b - 1/r + 1/g =", 1/b - 1/r + 1/g)
    print("b+r+g=", b+r+g)
    print("b*r*g=", b*r*g)
    print("b+r+g-brg=", b+r+g-b*r*g)
    
