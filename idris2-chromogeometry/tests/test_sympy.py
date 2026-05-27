import sympy as sp

x1, y1, x2, y2, x3, y3 = sp.symbols('x1 y1 x2 y2 x3 y3')

def q(m, a, b, c, d):
    dx = c - a; dy = d - b
    if m == 'B': return dx**2 + dy**2
    if m == 'R': return dx**2 - dy**2
    if m == 'G': return dy**2 - dx**2

def spread(m):
    q1 = q(m, x1, y1, x2, y2)
    q2 = q(m, x2, y2, x3, y3)
    q3 = q(m, x3, y3, x1, y1)
    arch = 2*(q1**2 + q2**2 + q3**2) - (q1 + q2 + q3)**2
    num = arch
    den = 4 * q1 * q3
    return num, den

nb, db = spread('B')
nr, dr = spread('R')
ng, dg = spread('G')

# we know nr/dr == ng/dg
# Let sb = nb/db, sr = nr/dr
sb = nb / db
sr = nr / dr

# try to find relation between sb and sr
# sum = sb + 2*sr, prod = sb * sr**2
