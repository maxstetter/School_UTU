import connect_four_model
import copy
import random

def agent_function(env, agent):
    observation, reward, termination, truncation, info = env.last()
    if termination or truncation:
        action = None
    else:
        action = None
        searchable_env = connect_four_model.ConnectFour()
        searchable_env.copy_from_env(env)
        for possible_action in searchable_env.legal_moves(): # ACTIONS(searchable_env)
            env1 = copy.deepcopy(searchable_env)             # RESULT(searchable_env, possible_action)
            env1.step(possible_action)                       #
            if env1.game_over():                             # ~GOAL-TEST(env1)
                action = possible_action
        if action is None:
            action = random.choice(searchable_env.legal_moves())
    return action

