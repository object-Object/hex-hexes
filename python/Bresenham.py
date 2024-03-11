from __future__ import annotations
from dataclasses import dataclass
from typing import Callable, Iterator, Literal

def sign(x: float) -> Literal[1, 0, -1]:
    return 1 if x > 0 else -1 if x < 0 else 0

@dataclass
class Point:
    x: float
    y: float
    z: float

    @classmethod
    def zero(cls) -> Point:
        return Point(0, 0, 0)

    def sign(self) -> Point:
        return Point(sign(self.x), sign(self.y), sign(self.z))
    
    def hadamard(self, other: Point) -> Point:
        return Point(self.x * other.x, self.y * other.y, self.z * other.z)

    def __add__(self, other: float | int | Point) -> Point:
        match other:
            case float() | int():
                return Point(self.x + other, self.y + other, self.z + other)
            case Point():
                return Point(self.x + other.x, self.y + other.y, self.z + other.z)
    
    def __sub__(self, other: float | int | Point) -> Point:
        return self + (-other)

    def __mul__(self, other: float | int) -> Point:
        return Point(self.x * other, self.y * other, self.z * other)
    
    def __neg__(self) -> Point:
        return self * -1
    
    def __iter__(self) -> Iterator[float]:
        return iter((self.x, self.y, self.z))
    
    def __repr__(self) -> str:
        return f"({self.x}, {self.y}, {self.z})"

def bresenham(p0: Point, p1: Point, f: Callable[[Point], None]):
    diff = p1 - p0
    s = diff.sign()
    dp = diff.hadamard(s)

    dm = int(max(dp.x, dp.y, dp.z))
    e = Point(dm / 2, dm / 2, dm / 2)

    for _ in range(dm + 1):
        e -= dp

        mask = e.sign() - 1
        mask -= mask.sign()

        e -= mask * dm

        f(p0)
        p0 -= mask.hadamard(s)

out = []
bresenham(Point(0.5, 0.5, 0.5), Point(2.5, 7.5, 4.5), lambda p: out.append(p))
print(out)
