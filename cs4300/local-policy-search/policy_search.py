import gymnasium as gym
import random


# Generates an array of moves. Takes an integer for the size of the array.
def default_policy(x):
    local_policy = []
    for i in range(x):
        j = random.randint(0,3)
        local_policy.append(j)
    return local_policy

# Write the policy to policy.txt
def write_policy(policy):
    file = open("policy.txt", "w")
    for i in policy:
        file.write(str(i))
    file.close()

# Read from policy.txt and return an array of the policy.
def decode_policy():
    decoded = []
    file = open("policy.txt", "r")

    while 1:
        # read each character
        char = file.read(1)
        if not char:
            break

        decoded.append(int(char))

    file.close()
    return decoded

# Calculate the observation given row and col. Returns int
def calc_observation(row, col):
    return ((row * 12) + col)



def manhattan(point1, point2):
    x1, y1 = point1
    x2, y2 = point2
    return abs(x1 -x2) + abs(y1 -y2)

def evaulate_policy(env, policy):
    observation, info = env.reset()
    terminated, truncated = False
    total_reward = 0

    while not (terminated or truncated):
        action = policy[observation]
        observation, reward, terminated, truncated, info = env.step(action)
        # TODO: adjust reward based upon manhattan distance to reward. The goal is to differentiate policies that are different but give the same score.
        total_reward += reward
    return total_reward


def generate_neighbors(x):
	pass

def hill_climbing(initial_solution, objective_function, max_iterations):
    current_solution = initial_solution
    current_value = objective_function(current_solution)

    for _ in range(max_iterations):
        neighbors = generate_neighbors(current_solution)  # Get neighboring solutions
        next_solution = max(neighbors, key=objective_function)  # Choose the best neighbor
        next_value = objective_function(next_solution)

        if next_value <= current_value:
            break  # Stop if no better neighbor found

        current_solution, current_value = next_solution, next_value

    return current_solution, current_value

# Takes the desired algorithm, number of iterations to run the algorithm.
# Creates a policy from scratch and runs it through povided algorithm. Returns best_policy and total_reward as a tuple.
#def create_policy(algorithm, iterations, moves):
def process_policy(iterations):
    # Policy generation

    best_policy = decode_policy()

    # Create Env
    #env = gym.make('CliffWalking-v0', render_mode="human")
    env = gym.make('CliffWalking-v0')


    # START of a sequence or episode
    observation, info = env.reset()
    x, y, vx, vy, angle, v_angle, leg1, leg2 = observation

    terminated = False
    truncated = False
    total_reward = 0
    action = 0


    while not (terminated or truncated):
        if vy < -0.8:
            action = 2
        elif vy > -0.1:
            action = 0
        observation, reward, terminated, truncated, info = env.step(action)
        x, y, vx, vy, angle, v_angle, leg1, leg2 = observation

        if vx < 0:
            action = 3
        elif vx > 0:
            action = 1

        total_reward += reward


    print('total_reward: ', total_reward)
    # END 

    env.close()
    return tuple(best_policy, total_reward)