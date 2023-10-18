import gymnasium as gym
import random
from policy_search import decode_policy
from policy_search import calc_observation

# Create agent and run it.
def create_agent(render):
    mode = "default"
    if render ==  1:
        mode = "human"

    # Decode policy:
    policy = decode_policy()
    print("Policy being used: {}".format(policy))

    # create
    if mode == "human":
        env = gym.make('CliffWalking-v0', render_mode="human")
    else:
        env = gym.make('CliffWalking-v0')
    env = gym.wrappers.TimeLimit(env, max_episode_steps=50)



    # START of a sequence or episode
    observation, info = env.reset()

    num_cols = 12

    # Convert the observation to row and column numbers


    terminated = False
    truncated = False
    total_reward = 0


    while not (terminated or truncated):
        for action in policy:
            observation, reward, terminated, truncated, info = env.step(action)
        #x, y, vx, vy, angle, v_angle, leg1, leg2 = observation # might not need this line.
            row_number = observation // num_cols
            col_number = observation % num_cols
            print("Observation: ", observation)
            print("calculated: ", calc_observation(row_number, col_number))
            print("row_number: ", row_number)
            print("col_number: ", col_number)

        total_reward += reward


    print('total_reward: ', total_reward)
    # END 

    env.close()
    return total_reward
