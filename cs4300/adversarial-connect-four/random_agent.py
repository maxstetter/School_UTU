def agent_function(env, agent):
    observation, reward, termination, truncation, info = env.last()
    if termination or truncation:
        action = None
    else:
        mask = observation["action_mask"]
        action = env.action_space(agent).sample(mask)  # this is where you would insert your policy
    return action

