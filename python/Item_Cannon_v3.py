import math
from typing import Callable, Literal

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.axes import Axes
from mpl_toolkits.axes_grid1 import make_axes_locatable
from tqdm import tqdm

g = 0.04
k = 0.02

z_0 = -1 / math.e
z_1 = 2.008217812
N = 4
M = 3
P_1n = [
    -9.999999404e-1,
    5.573005216e-2,
    2.126973249,
    8.135112368e-1,
    1.632488015e-2,
]
Q_1n = [
    1,
    2.275906560,
    1.367597014,
    1.861582345e-1,
]


def W(z: float) -> float:
    assert z_0 <= z < z_1, f"z out of range for W: {z}"
    x = math.sqrt(z - z_0)
    return sum(P_1n[n] * x**n for n in range(N)) / sum(Q_1n[m] * x**m for m in range(M))


def dW_dz(z: float) -> float:
    return 1 / (z + math.exp(W(z)))


def clamp(x: float, min_x: float, max_x: float) -> float:
    return max(min_x, min(x, max_x))


def sign(x: float) -> Literal[-1, 0, 1]:
    if x < 0:
        return -1
    if x > 0:
        return 1
    return 0


def bisect(
    f: Callable[[float], float],
    a: float,
    b: float,
    tolerance: float,
    max_steps: int,
    debug: bool = False,
):
    f_a = f(a)
    f_b = f(b)
    assert a < b and (f_a > 0 and f_b < 0 or f_a < 0 and f_b > 0)

    for n in range(max_steps):
        if debug:
            print(f"{n}: [{a}, {b}]")

        c = (a + b) / 2
        f_c = f(c)
        if f_c == 0 or (b - a) / 2 < tolerance:
            return c

        if sign(f_c) == sign(f(a)):
            a = c
        else:
            b = c


def solve(X: float, Y: float, debug: bool = False) -> tuple[float, float]:
    """returns angle, speed"""

    def V(a: float) -> float:
        exp = math.exp(k**2 * (Y - X * math.tan(a)) / g - 1)
        return (k * X) / (math.cos(a) * (W(-exp) + 1))

    def dV_da(a: float) -> float:
        exp = math.exp(k**2 * (Y - X * math.tan(a)) / g - 1)
        return (
            k
            * X
            / math.cos(a)
            * (
                -(k**2 * X / (math.cos(a) ** 2) * exp * dW_dz(-exp)) / g
                + math.tan(a) * W(-exp)
                + math.tan(a)
            )
        ) / ((W(-exp) + 1) ** 2)

    # exclusive
    min_a = math.atan(Y / X)
    max_a = math.tau / 4

    range_a = max_a - min_a
    assert range_a > 0
    margin = range_a / 1000

    a = bisect(
        f=dV_da,
        a=min_a + margin,
        b=max_a - margin,
        tolerance=0.001,
        max_steps=50,
        debug=debug,
    )
    assert a is not None, "failed to find local minimum"

    if debug:
        print(f"V'(a): {dV_da(a)}")

    return a, V(a)


if __name__ == "__main__":
    a, v = solve(X=100, Y=0, debug=True)
    print(f"{a=}, {v=}")

    x_max = 1000
    y_max = 384
    x = np.arange(1, x_max + 1)
    y = np.arange(-y_max, y_max + 1)

    a_data = list[list[float]]()
    v_data = list[list[float]]()
    for j in tqdm(y):
        a_data.append([])
        v_data.append([])
        for i in x:
            a, v = solve(X=float(i), Y=float(j))
            a_data[-1].append(a * 360 / math.tau)
            v_data[-1].append(v)

    ax1: Axes
    ax2: Axes
    fig, (ax1, ax2) = plt.subplots(nrows=2, ncols=1)

    a = np.array(a_data)
    im1 = ax1.imshow(
        a,
        extent=(x.min(), x.max(), y.min(), y.max()),
        interpolation="none",
        origin="lower",
    )
    ax1.set_title("angle from horizontal (deg)")

    divider = make_axes_locatable(ax1)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    fig.colorbar(im1, cax=cax, orientation="vertical")

    v = np.array(v_data)
    im2 = ax2.imshow(
        v,
        extent=(x.min(), x.max(), y.min(), y.max()),
        interpolation="none",
        origin="lower",
    )
    ax2.set_title("launch speed (b/t)")

    divider = make_axes_locatable(ax2)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    fig.colorbar(im2, cax=cax, orientation="vertical")

    fig.tight_layout()
    plt.show()
