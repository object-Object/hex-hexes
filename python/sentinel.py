import math


def get_coord(i: int, size: int) -> tuple[int, int, int]:
    y = -(i // size**2)
    # y = size - i // size**2 - 1

    x = (-i - 1 if (i // size) % 2 == 0 else i) % size
    # x = (i - (i // size % 2) * (2 * i + 1)) % size

    z = ((-i - 1 if y % 2 == 0 else i) // size) % size
    # z = (i // size - ((i // size**2) % 2) * (2 * (i // size) + 1)) % size

    return (x, y, z)


def get_offset(i: int, size: int) -> tuple[int, int, int]:
    if (i + 1) % size**2 == 0:
        return (0, 1, 0)
    if (i // size**2) % 2 == 0:
        sign = 1
        i = (-i - 1) % size**2
    else:
        sign = -1
        i = i % size**2
    if i % size == 0:
        return 0, 0, sign
    if (i // size) % 2 == 0:
        return sign, 0, 0
    return -sign, 0, 0


size = 8

# for i in range(size**3):
#     y = i // size**2
#     values = [
#         i,
#         (i + 1) % size**2,
#         # (i - (i // size % 2) * (2 * i + 1)) % size,
#         # (i // size) % size,
#         # (i // size**2 % 2),
#         # i % size + ((i // size) % 2) * ((-(i + 1) % size) * 2 + 1 - size),
#         # (i // size) % 2,
#         # (i - (i * 2 + 1)) % size,
#         # y,
#         # (i - (y % 2) * (2 * i + 1)) % size**2,
#         # (i - (y % 2) * 2 * i - (y % 2)) % size**2,
#     ]

#     print("\t".join(str(x) for x in values))

coords = [get_coord(i, size) for i in range(size**3)]

# pos = (0, 0, 0)
# coords = []
# for i in range(size**3):
#     coords.append(pos)
#     offset = get_offset(i, size)
#     pos = tuple(a + b for a, b in zip(pos, offset))


for coord_i in coords:
    print(coord_i)

print()

if len(set(coords)) != size**3:
    print(f"expected: {size**3}")
    print(f"  actual: {len(set(coords))}")
    print()

for i, j in zip(range(size**3), range(1, size**3)):
    coord_i = coords[i]
    coord_j = coords[j]
    offset = tuple(x_j - x_i for x_i, x_j in zip(coord_i, coord_j))
    distance = math.sqrt(sum(x**2 for x in offset))
    if distance != 1:
        print(f"{distance:.2f}\t{i}\t{coord_i}\t{j}\t{coord_j}")
