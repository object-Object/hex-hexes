import math
from typing import List, Tuple
import numpy as np

# item / tnt
gravity = 0.04
drag = 0.02

# pearl
# gravity = 0.03
# drag = 0.01

terminal_vel = gravity / drag

def newton(f, x0, df, epsilon, iterations):
    x = x0
    for _ in range(iterations):
        y = f(x)
        if y is None:
            return None
        if abs(y) < epsilon:
            return x

        dy = df(x)
        if dy == 0:
            return None

        x -= y/dy
    return None

def f1(distance, theta, speed) -> float | None:
    cost = math.cos(theta)
    sint = math.sin(theta)
    vx = speed * cost
    vy = speed * sint
    logarg = 1-drag*distance/vx
    if logarg <= 0:
        return None
    return (distance*(terminal_vel+vy)/vx - terminal_vel*math.log(logarg)/math.log(1 - drag))-0.1

def get_angle(distance):
    angle_guess = (73.4808 * 0.995991**distance + 17.4676)*math.tau/360
    if distance < 150:
        speed = 1.74489 + 0.800907 * math.log(distance)
    else:
        speed = 36.7299 * 1.0004**distance - 33.2558

    def f(theta):
        cost = math.cos(theta)
        sint = math.sin(theta)
        vx = speed * cost
        vy = speed * sint
        logarg = 1-drag*distance/vx
        if logarg <= 0:
            return None
        return (distance*(terminal_vel+vy)/vx - terminal_vel*math.log(logarg)/math.log(1 - drag))-0.1
    
    def df(theta):
        cost = math.cos(theta)
        sint = math.sin(theta)
        tant = sint / cost
        vx = speed * cost
        return distance + gravity*distance*tant / ((-drag*distance+vx)*math.log(1 - drag)) + gravity*distance*tant/(drag*vx) + distance*tant**2

    angle = newton(f, angle_guess, df, 0.1, 15)
    if angle is None:
        return (None, None)
    return (angle * 360 / math.tau, speed)

# def get_speed(distance):
#     angle = (73.4808 * 0.995991**distance + 17.4676)*math.tau/360
#     if distance < 150:
#         speed_guess = 1.74489 + 0.800907 * math.log(distance)
#     else:
#         speed_guess = 36.7299 * 1.0004**distance - 33.2558

#     def f(speed):
#         vx = speed * math.cos(angle)
#         vy = speed * math.sin(angle)
#         logarg = 1 - drag*distance/vx
#         if logarg <= 0:
#             return None
#         return (distance * (terminal_vel + vy) / vx - terminal_vel * math.log(logarg) / math.log(1 - drag))
    
#     def df(speed):
#         sec_angle = 1 / math.cos(angle)
#         return (gravity * distance * sec_angle * (-speed * (drag + math.log(1 - drag)) + drag * distance * math.log(1 - drag) * sec_angle))/(drag * speed**2 * math.log(1 - drag) * (speed - drag * distance * sec_angle))
    
#     speed = newton(f, speed_guess, df, 0.001, 15)
#     if speed is None:
#         return (None, None)
#     return (angle, speed)

def round_abacus(n):
    return np.round(n, 4 if n >= 1 else 5)

# want it to work for these ranges:
# dx         dy
# [1, 1000]  [-50,  100]

max_dx = 1000
min_dy = -50
max_dy = 100
# min_dy = -(max_dy := 0)

# angle_scale = 100
# speed_scale = 100
# def brute_angle_speed(dx: int, dy: int) -> Tuple[float, float] | Tuple[None, None]:
#     global start_angle, start_speed
#     epsilon = 0.1 if dx > 10 else 0.05
#     if start_angle <= 0:
#         raise Exception
#     for angle in range(start_angle, 0, -1):
#         angle /= angle_scale
#         for speed in range(1, speed_scale * 100, 1):
#             speed /= speed_scale
#             y = f1(dx, angle * math.tau / 360, speed)
#             if y is not None and abs(y - dy) <= epsilon:
#                 start_angle = int(angle * angle_scale)
#                 return (angle, speed)
#     return (None, None)

# brute_results: list[list[float | None]] = []
# # for dy in [-100, 0, 100]:
# for dy in [-8]:
#     start_angle = 85 * angle_scale
#     for dx in range(1, max_dx + 1):
#         print(f"\rBrute forcing dx={dx}, dy={dy}                ", end="")
#         match brute_angle_speed(dx, dy):
#             case (None, None):
#                 print(f"\rFailed dx={dx}, dy={dy}             ")
#                 brute_results.append([dx, dy, None, None])
#             case (angle, speed):
#                 brute_results.append([dx, dy, angle, speed])
# print()
# print(brute_results[-1])

# brute_results_array = np.array(brute_results)
# print(brute_results_array)
# print([list(v) for v in brute_results_array])

def hex_angle_speed_2(
    dx: int,
    dy: int,
) -> Tuple[float, float, int] | None:
    angle_range = 5
    speed_range = 2
    angle_iters = 180
    speed_iters = 64

    epsilon = 1
    ideal_epsilon = 0.1
    result = None

    if dx == 1 and dy > 80:
        direct_distance = math.sqrt(dx**2 + dy**2)
    else:
        direct_distance = dx

    angle_guess = min(89.5 - angle_range, 73.4808 * 0.995991**dx + 17.4676)

    if direct_distance < 150:
        speed_guess = 1.74489 + 0.800907 * math.log(direct_distance)
    else:
        speed_guess = 36.7299 * 1.0004**direct_distance - 33.2558

    iteration = 0
    for angle in np.linspace(angle_guess - angle_range, angle_guess + angle_range, angle_iters):
        iteration += 1
        for speed in np.linspace(speed_guess - speed_range, speed_guess + speed_range, speed_iters):
            y = f1(dx, angle * math.tau / 360, speed)
            if y is not None:
                diff = abs(y - dy)
                if diff <= ideal_epsilon:
                    return (angle, speed, iteration)
                if diff <= epsilon:
                    result = (angle, speed, iteration)
                    epsilon = diff

    return result

def hex_angle_speed_rad(
    dx: int,
    dy: int,
) -> Tuple[float, float] | None:
    angle_range = 0.087
    speed_range = 2
    angle_iters = 180
    speed_iters = 64

    epsilon = 1
    ideal_epsilon = 0.1
    result = None

    angle_guess = min(1.5621 - angle_range, 1.28248 * 0.995991**dx + 0.304867)

    if dx == 1 and dy > 80:
        direct_distance = math.sqrt(dx**2 + dy**2)
    else:
        direct_distance = dx

    if direct_distance < 150:
        speed_guess = 1.74489 + 0.800907 * math.log(direct_distance)
    else:
        speed_guess = 36.7299 * 1.0004**direct_distance - 33.2558

    for angle in np.linspace(angle_guess - angle_range, angle_guess + angle_range, angle_iters):
        for speed in np.linspace(speed_guess - speed_range, speed_guess + speed_range, speed_iters):
            y = f1(dx, angle, speed)
            if y is not None:
                diff = abs(y - dy)
                if diff <= ideal_epsilon:
                    return (angle, speed)
                if diff <= epsilon:
                    result = (angle, speed)
                    epsilon = diff

    return result


def hex_angle_speed_rad_simple_item(dx: float, dy: float) -> Tuple[float, float, int, float] | None:
    epsilon = 1
    result = None

    angle_guess = min(
        1.48,
        1.28 * 0.996**dx + 0.3
    )

    current_angle = angle_guess - 0.087

    if dx < 150:
        speed_guess = 1.745 + 0.8 * math.log(dx)
    else:
        speed_guess = 37 * 1.0004**dx - 33
    
    buffer = math.ceil((speed_guess + 2.1)**2 + 56) # conservative impulse cost guess + wisp buffer (46) + consume cost (10)
    current_speed = speed_guess - 2

    wisp_num = 0
    while True:
        for _ in range(63): # recursion limit >:(
            vx = current_speed * math.cos(current_angle)
            logarg = 1 - dx/(vx*50)
            logarg_valid = logarg > 0
            if not logarg_valid:
                logarg = 1
            if logarg_valid:
                vy = current_speed*math.sin(current_angle)
                y = (2 + vy)*dx/vx + 98.997*math.log(logarg)
            else:
                y = dy + 10
            diff = abs(y - dy)
            if diff <= epsilon: # use one-pattern hermes for these? (surgeon, vv)
                result = (current_angle, current_speed, buffer, diff) # [speed, angle]
                epsilon = diff
            current_speed += 4/63
            if diff <= 0.25:
                break
        current_speed -= 4 # this is fine because if we broke early the next condition will exit
        current_angle += 0.000972 # 2*0.087/179 = 2*angle_range/(angle_iters - 1)
        wisp_num += 1
        if result is not None and (epsilon <= 0.25 or wisp_num >= 180):
            return result # launch the item
        else:
            if wisp_num >= 180:
                return None # don't launch the item
            else:
                continue

def hex_angle_speed_rad_simple_item_2_worker(dx: float, dy: float, current_speed: float, current_angle: float, epsilon: float) -> Tuple[float, Tuple[float, float]] | None:
    result = None
    wisp_num = 0
    while True:
        for _ in range(63): # recursion limit >:(
            vx = current_speed * math.cos(current_angle)
            logarg = 1 - dx/(vx*50)
            logarg_valid = logarg > 0
            if not logarg_valid:
                logarg = 1
            if logarg_valid:
                vy = current_speed*math.sin(current_angle)
                y = (2 + vy)*dx/vx + 98.997*math.log(logarg)
            else:
                y = dy + 10
            diff = abs(y - dy)
            if diff <= epsilon:
                result = (epsilon, (current_speed, current_angle))
                epsilon = diff
            current_speed += 4/63
            if diff <= 0.25:
                break
        current_speed -= 4 # this is fine because if we broke early the next condition will exit
        current_angle += 0.000972 # 2*0.087/179 = 2*angle_range/(angle_iters - 1)
        wisp_num += 1
        if result is not None and (epsilon <= 0.1 or wisp_num >= 18):
            return result
        elif wisp_num >= 18:
            return None
        else:
            continue

def hex_angle_speed_rad_simple_item_2(dx: float, dy: float) -> Tuple[float, float, int, float] | None:
    epsilon = 1
    result = None

    angle_guess = min(
        1.48,
        1.28 * 0.996**dx + 0.3
    )

    current_angle = angle_guess - 0.087

    if dx < 150:
        speed_guess = 1.745 + 0.8 * math.log(dx)
    else:
        speed_guess = 37 * 1.0004**dx - 33
    
    buffer = math.ceil((speed_guess + 2.1)**2 + 56) # conservative impulse cost guess + wisp buffer (46) + consume cost (10)
    current_speed = speed_guess - 2

    for _ in range(10):
        if worker_result := hex_angle_speed_rad_simple_item_2_worker(dx, dy, current_speed, current_angle, epsilon):
            (worker_epsilon, (worker_speed, worker_angle)) = worker_result
            if worker_epsilon <= epsilon:
                epsilon = worker_epsilon
                result = (worker_angle, worker_speed, buffer, worker_epsilon) # [speed, angle]
            if epsilon <= 0.1:
                return result
        current_angle += 2*0.087/10

    return result # launch if we got a result; die either way so the links break


def worker(dy) -> Tuple[List[float], List[List[float]]]:
    residuals: List[float] = []
    failures: List[List[float]] = []
    for dx in range(1, max_dx + 1):
        match hex_angle_speed_rad_simple_item_2(dx, dy):
            case None:
                # predict_results.append([dx, dy, None, None])
                failures.append([dx, dy])
            case (_angle, _speed, _buffer, res):
                residuals.append(res)
                # predict_results.append([dx, dy, angle, speed])
    print(f"Done dy={dy}")
    return (residuals, failures)

# if (result := hex_angle_speed_rad_simple_item_2(5, 0)):
#     (angle, speed, buffer, res) = result
#     print(f"angle={angle:.04f}, speed={speed:.04f}, buffer={buffer}, res={res:.04f}")

# if __name__ == "__main__":
#     pool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
#     residuals: List[float] = []
#     failures: List[List[float]] = []
#     for (worker_residuals, worker_failures) in pool.map(worker, range(min_dy, max_dy + 1)):
#         residuals.extend(worker_residuals)
#         failures.extend(worker_failures)

#     residuals.sort()
#     print(f"Residuals: min={residuals[0]:.02f} max={residuals[-1]:.02f} avg={np.mean(residuals):.02f}")

#     if failures:
#         failures_array = np.array(failures)
#         plt.figure(figsize=(22, 12))
#         plt.plot(failures_array[:,0], failures_array[:,1], "o", markersize=4)
#         plt.tight_layout()
#         plt.show()
#     else:
#         print("Great success!")


# def loop(angle_range, speed_range, angle_iters, speed_iters):
#     for dy in range(-max_dy, max_dy + 1):
#         for dx in range(1, max_dx + 1):
#             if hex_angle_speed_2(dx, dy, angle_range, speed_range, angle_iters, speed_iters) is None:
#                 return False
#     return True

# working = []
# for angle_range in np.arange(1, 4 * 2 + 1) / 2:
#     for speed_range in np.arange(1, 2 * 2 + 1) / 2:
#         for angle_iters in range(5, 66, 5):
#             for speed_iters in range(5, 66, 5):
#                 print("\r", angle_range, speed_range, angle_iters, speed_iters, "         ", end="")
#                 if loop(angle_range, speed_range, angle_iters, speed_iters):
#                     working.append((angle_range, speed_range, angle_iters, speed_iters))
# print()
# print(working)

# distance_x = 10
# distance_y = 0
# speed, angle = get_everything(distance_x, distance_y)
# if speed is None:
#     print(angle)
# else:
#     print(f"Launching {distance_x} horizontal, {distance_y} vertical:\nspeed = {round_abacus(speed)}\nangle = {round_abacus(angle)} rad ({round_abacus(angle*360/math.tau)}⁰)")

# for distance in range(1, 5000):
#     success = False
#     for angle in range(85, 9, -5):
#         try:
#             if get_speed(distance, angle) is not None:
#                 success = True
#                 break
#         except Exception:
#             pass
#     if not success:
#         print(f"Max distance: {distance}")
#         break

# distance = 20
# for angle in range(85, 9, -1):
#     speed = get_speed(distance, angle)
#     if speed is not None:
#         break
# print(f"Launching {distance} blocks: speed={np.round(speed, 4 if speed >= 1 else 5)}, angle={angle*math.tau/360} rad")

# x_vals = np.arange(1, 101)
# angle_vals = []
# speed_vals = []
# for x in x_vals:
#     angle, speed = get_angle_2(x)
#     if x == 20:
#         print(speed, angle)
#     angle_vals.append(angle*360/math.tau if angle is not None else angle)
#     speed_vals.append(speed)

# fig, ax1 = plt.subplots()
# ax2 = ax1.twinx()

# ax1.plot(x_vals, angle_vals, color="blue", label="result")
# ax1.set_xlabel("distance")
# ax1.set_ylabel("launch angle (deg)", color="blue")
# ax1.legend()

# ax2.plot(x_vals, speed_vals, color="red")
# ax2.set_ylabel("launch speed", color="red")

# plt.tight_layout()
# plt.get_current_fig_manager().window.state("zoomed")
# plt.show()
