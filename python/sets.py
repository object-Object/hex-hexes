import math
from dataclasses import dataclass
import random

@dataclass(frozen=True)
class Vec:
    x: float
    y: float
    z: float

    def round(self) -> tuple[int, int, int]:
        # in hex: floor(vec + 0.5)
        return round(self.x), round(self.y), round(self.z)


SIZE = 128
class VecSet:
    _data: list[list[Vec]] = [[] for _ in range(SIZE)]

    def _hash(self, vec: Vec) -> int:
        # big-ish prime numbers
        p1 = 7321 # aqaaeaqaaqaeaaqqdeaaqqaaw
        p2 = 5653 # aqaaqaeaaqawaewaawaaw
        p3 = 6451 # aqaaweawawaqaawqaawaaqe

        x, y, z = vec.round()
        # xor (exclusionary)
        return ((x * p1) ^ (y * p2) ^ (z * p3)) % SIZE

    def _bucket(self, vec: Vec) -> list[Vec]:
        return self._data[self._hash(vec)]

    def add(self, vec: Vec):
        bucket = self._bucket(vec)
        # locator
        if vec not in bucket:
            # integration
            bucket.append(vec)
    
    def remove(self, vec: Vec):
        try:
            # locator, excisor
            self._bucket(vec).remove(vec)
        except ValueError:
            pass
    
    def contains(self, vec: Vec) -> bool:
        # locator
        return vec in self._bucket(vec)


# note: normalize vectors by subtracting the player's head position from them (vec - head)
# ie. position within ambit
vecset = VecSet()

LIMIT = 32
# all_vecs = []
# for x in range(-LIMIT, LIMIT+1):
#     for y in range(-LIMIT, LIMIT+1):
#         for z in range(-LIMIT, LIMIT+1):
#             if math.sqrt(x**2 + y**2 + x**2) < 32:
#                 all_vecs.append(Vec(x, y, z))

# for vec in random.sample(all_vecs, 2048):
#     vecset.add(vec)

n = lambda: random.randint(-2048, 2048)
for _ in range(512):
    vecset.add(Vec(n(), n(), n()))

sizes = [len(b) for b in vecset._data]
print(f"min={min(sizes)} mean={sum(sizes)/len(sizes)} median={sorted(sizes)[len(sizes)//2]} max={max(sizes)}")
