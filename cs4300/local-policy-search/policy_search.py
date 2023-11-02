import gymnasium as gym
import numpy as np
import random
# print(observation)

# Write the policy to policy.txt
def write_policy(policy):
    file = open("policy.txt", "w")
    for i in policy:
        file.write(str(i))
    file.close()

# Generates an array of moves. Takes an integer for the size of the array.
def default_policy(x):
    local_policy = []
    for i in range(x):
        j = random.randint(0,3)
        local_policy.append(j)
    return local_policy

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

# Decode observation into row and col. Returns tuple (row, col)
def decode_observation(observation):
    num_cols = 12 # number of columns in cliffwalking.
    row_number = observation // num_cols
    col_number = observation % num_cols
    return (row_number, col_number)


def neighbor_policies(policy, bad_index):
    bad_action = policy[bad_index]
    new_policy1 = policy[:]
    new_policy2 = policy[:]
    new_policy3 = policy[:]
    if bad_action == 0:
        new_policy1[bad_index] = 1
        new_policy2[bad_index] = 2
        new_policy3[bad_index] = 3
    elif bad_action == 1:
        new_policy1[bad_index] = 0
        new_policy2[bad_index] = 2
        new_policy3[bad_index] = 3
    elif bad_action == 2:
        new_policy1[bad_index] = 0
        new_policy2[bad_index] = 1
        new_policy3[bad_index] = 3
    elif bad_action == 3:
        new_policy1[bad_index] = 0
        new_policy2[bad_index] = 1
        new_policy3[bad_index] = 2
    return new_policy1, new_policy2, new_policy3


def find_replacement(policy):
    position = [3,0]
    iterations = 0
    bad_action_index = None
    found_goal = None
    for i in policy:
        # MOVE UP
        if i == 0:
            if position[0] == 0:
                bad_action_index = iterations
                break
            else:
                position[0] -= 1
        # MOVE RIGHT
        elif i == 1:
            if position == [3,0]:
                bad_action_index = iterations
                break
            elif position[1] == 11:
                bad_action_index = iterations
                break
            else:
                position[1] += 1
        # MOVE DOWN
        elif i == 2:
            if position[0] == 2 and position[1] != 11:
                bad_action_index = iterations
                break
            elif position[0] == 3:
                bad_action_index = iterations
                break
            else:
                position[0] += 1
        # MOVE LEFT
        elif i == 3:
            if position[1] == 0:
                bad_action_index = iterations
                break
            else:
                position[1] -= 1
        # GOAL CHECK
        if position == [3,11]:
            found_goal = policy[:iterations+1]
            break
        iterations += 1
    return bad_action_index, found_goal, position
            
def manhattan_distance(current, goal):
    y1 = current[0]
    x1 = current[1]
    y2 = goal[0]
    x2 = goal[1]
    condition = 0
    if current == [3,0]:
        condition = 2
    return abs(x1 - x2) + abs(y1 - y2) + condition

def get_reward(policy, env):
    total_reward = 0
    for i in policy:
        observation, reward, terminated, truncated, info = env.step(i)
        total_reward += reward
    # might need to reset env right here
    observation, info = env.reset()
    return total_reward

def update_position(action, position):
    # will update the position only if it's a valid action
    # else it will keep the current position
    new_position = position[:]
    if action == 0:
        if new_position[0] == 0:
            pass
        else:
            new_position[0] -= 1
    elif action == 1:
        if new_position == [3,0] or new_position[1] == 11:
            pass
        else:
            new_position[1] += 1
    elif action == 2:
        if new_position[0] == 2 and new_position[1] != 11:
            pass
        elif new_position[0] == 3:
            pass
        else:
            new_position[0] += 1
    elif action == 3:
        if new_position[1] == 0:
            pass
        else:
            new_position[1] -= 1
    return new_position

def best_neighbor(neighbor1, neighbor2, neighbor3, position, index):
    action1 = neighbor1[index]
    action2 = neighbor2[index]
    action3 = neighbor3[index]
    actions = [action1, action2, action3]
    best_n = None
    best_score = 100
    iteration = 1
    for i in actions:
        reset_position = position[:]
        new_position = update_position(i, reset_position)
        #print(new_position)
        if new_position != reset_position:
            score = manhattan_distance(new_position, [3,11])
            #print(score)
            if score < best_score:
                best_score = score
                if iteration == 1:
                    best_n = neighbor1
                elif iteration == 2:
                    best_n = neighbor2
                elif iteration == 3:
                    best_n = neighbor3
        iteration += 1
    return best_n
    
def hill_climbing(policy, env):
    best_policy = policy[:]
    best_reward = get_reward(policy, env)
    
    for i in range(50):
        bad_index, goal_test, position = find_replacement(policy)
        if bad_index == None and goal_test == None:
            return None, -50000
        elif goal_test == None:
            neighbor1, neighbor2, neighbor3 = neighbor_policies(policy, bad_index)
            best_n = best_neighbor(neighbor1, neighbor2, neighbor3, position, bad_index)
            policy = best_n
        else:
            new_reward = get_reward(goal_test, env)
            if new_reward > best_reward:
                best_policy = goal_test
                best_reward = new_reward
            break
    return best_policy, best_reward

def process_policy(iterations):
    env = gym.make("CliffWalking-v0")#, render_mode = "human")
    env = gym.wrappers.TimeLimit(env, max_episode_steps=50)
    observation, info = env.reset()

    final_policy = []
    final_reward = -99999999
    for i in range(iterations):
        initial_policy = default_policy(50)
        policy, reward = hill_climbing(initial_policy, env)
        if reward > final_reward:
            final_policy = policy
            final_reward = reward
    print("Final Policy: ", final_policy)
    print("Final_Reward: ", final_reward)
    write_policy(final_policy)

    env.close()