import math
import numpy as np
import matplotlib.pyplot as plt

DUST_UNIT = 10000
SHARD_UNIT = 5 * DUST_UNIT

# AC v1.4b
WISP_COST_PER_TICK = SHARD_UNIT/20
EXP_SCALE = 1/30

# latest Hexal commit
# WISP_COST_PER_TICK = DUST_UNIT/20
# EXP_SCALE = 1/60

cost = lambda x: WISP_COST_PER_TICK + EXP_SCALE * math.sqrt(x)

def get_cyclic_ticks(media: float):
    ticks = 1 # media check happens before deducting media
    media *= DUST_UNIT
    while media - cost(media) >= 0:
        media -= cost(media)
        ticks += 1
    return ticks

target_life = 71
media = 1
life = 0
while True:
    if (life := get_cyclic_ticks(media)) >= target_life:
        break
    media += 1
print(f"{media} dust lives for {life} ticks (target: {target_life})")

# print("dust | ticks")
# for media in range(10, 1000, 10):
#     print(f"{str(media).rjust(4)} | {get_cyclic_ticks(media)}")
