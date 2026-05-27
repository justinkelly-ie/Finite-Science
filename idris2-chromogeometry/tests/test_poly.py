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

for _ in range(3):
    while True:
        x1, y1 = random.randint(-10,10), random.randint(-10,10)
        x2, y2 = random.randint(-10,10), random.randint(-10,10)
        x3, y3 = random.randint(-10,10), random.randint(-10,10)
        b = spread('B', x1, y1, x2, y2, x3, y3)
        r = spread('R', x1, y1, x2, y2, x3, y3)
        g = spread('G', x1, y1, x2, y2, x3, y3)
        if b != 0 and r != 0 and g != 0: break
    
    print(f"b={b} r={r} g={g}")
    print("b+r+g =", b+r+g)
    print("b*r*g =", b*r*g)
    print("1/b + 1/r + 1/g =", 1/b + 1/r + 1/g)
    print("b^2+r^2+g^2 =", b**2+r**2+g**2)
    print("(b+r+g)^2 / (brg) =", (b+r+g)**2 / (b*r*g))
    print("(1/b+1/r+1/g)^2 / (1/brg) =", (1/b+1/r+1/g)**2 * b*r*g)
    print("---------")
