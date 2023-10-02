import gymnasium as gym
import random

def create_agent():
    # create
    env = gym.make('LunarLander-v2')


    # START of a sequence or episode
    observation, info = env.reset()
    x, y, vx, vy, angle, v_angle, leg1, leg2 = observation

    terminated = False
    truncated = False
    total_reward = 0
    action = 0


    while not (terminated or truncated):
        if vy < -0.1:
            action = 2
        elif vy > -0.05:
            action = 0
        observation, reward, terminated, truncated, info = env.step(action)
        x, y, vx, vy, angle, v_angle, leg1, leg2 = observation

        if v_angle > 0.01:
            action = 3
        elif v_angle < -0.01:
            action = 1

        total_reward += reward


    print('total_reward: ', total_reward)
    # END 

    env.close()
    return total_reward
