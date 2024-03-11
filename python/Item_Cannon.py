import math
from typing import Callable
import matplotlib.pyplot as plt


def newton(f: Callable[[float], float], x0: float, df: Callable[[float], float], epsilon: float, iterations: int):
    x = x0
    for _ in range(iterations):
        y = f(x)
        if abs(y) < epsilon:
            return x

        dy = df(x)
        if dy == 0:
            return None

        x -= y/dy
    return None


# items
D = -0.02
D_inv = -50
g = 0.04
g_inv = 25
v_t = 2
v_0y_factor = 35

# ender pearls (untested)
# D = -0.01
# D_inv = -100
# g = 0.03
# g_inv = 100/3
# v_t = 3
# v_0y_factor = 70


# generic function
def get_launch_params(dx: float, dy: float) -> tuple[float, float] | None:
    v_0y = max(dy/v_0y_factor, 0) + min(dx*-D, 8) + v_t

    f = lambda t: v_t*t + dy - ((v_0y + v_t) / D)*(math.exp(D*t) - 1)
    df = lambda t: v_t - (v_0y + v_t)*math.exp(D*t)

    t0 = v_0y/g
    if dy < 0:
        t0 *= 2

    t1 = newton(f, t0, df, 1/1000, 10)
    if t1 is None:
        return None

    v_0x = 0
    delta = 0
    for _ in range(5):
        v_0x = g*(dx + delta)/v_t
        x1 = -v_0x*(1 - math.exp(D*t1))/D - dx
        delta -= x1
    
    return v_0x, v_0y


# refactored with all variables inlined and a lot of simplification
# this was my reference when writing the Hex version
def get_launch_params_hex(x_dist: float, y_dist: float) -> tuple[float, float]:
    # const
    v_0y = max(y_dist/35, 0) + min(x_dist/50, 8) + 2
    B = v_0y + 2
    
    # var
    t1 = v_0y * (50 if y_dist < 0 else 25)
    A = 0

    for _ in range(10):
        A = math.exp(t1/-50)
        y = y_dist + 2*t1 + B*50*(A - 1)
        if abs(y) < 1/1000:
            break

        t1 += y/(A*B - 2)
    return x_dist*(A**4 + A**3 + A**2 + A + 1)/50, v_0y


# x, y = get_launch_params_hex(1000, 0)
x = 1.063287068875*g*5/v_t
y = 2*v_t
print(x, y)
# print(math.sqrt(x**2 + y**2))
print(f"""/give @p hexcasting:focus{{data: {{"hexcasting:type": "hexcasting:list", "hexcasting:data": [{{"hexcasting:type": "hexcasting:double", "hexcasting:data": {x}d}}, {{"hexcasting:type": "hexcasting:double", "hexcasting:data": {y:.2f}d}}]}}}}""")

# check for gaps

def float_eq(a: float, b: float) -> bool:
    return abs(a - b) < 1e-10

# x_fails = []
# y_fails = []
# for dx in range(1, 3001):
#     for dy in range(-256, 257):
#         ans1 = get_launch_params(dx, dy)
#         ans2 = get_launch_params_hex(dx, dy)
#         if ans1 is None or ans2 is None or not (float_eq(ans1[0], ans2[0]) and float_eq(ans1[1], ans2[1])) or float_eq(ans1[0], 0):
#             x_fails.append(dx)
#             y_fails.append(dy)

# if x_fails:
#     plt.plot(x_fails, y_fails, "o")
#     plt.show()


# get costs

# x_vals = []
# y_vals = [[], [], []]
# dy_ = [-100, 0, 100]
# for dx in range(1001):
#     x_vals.append(dx)
#     for i, dy in enumerate(dy_):
#         if value := get_launch_params(dx, dy):
#             vx, vy = value
#             y_vals[i].append(vx**2 + vy**2)
#         else:
#             y_vals[i].append(None)

# for i, data in enumerate(y_vals):
#     plt.plot(x_vals, data, label=dy_[i])
# plt.legend()
# plt.title("Media cost by x distance")
# plt.show()
