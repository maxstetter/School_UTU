import gymnasium as gym
import random

# formula for decoding observation:
# Zoom 9/12/2023 at 15 minutes

#   Action Space:
# 0: Move south (down)
# 1: Move north (up)
# 2: Move east (right)
# 3: Move west (left)
# 4: Pickup passenger
# 5: Drop off passenger


# Create state class
class State:
    def __init__(self, taxi_row, taxi_col, passenger, destination, actions):
        self.taxi_row = taxi_row
        self.taxi_col = taxi_col
        self.passenger = passenger
        self.destination = destination
        self.actions = actions # ACTION(s)

# Create node class
class Node:
    def __init__(self, state, parent=None, action_taken=None):
        self.state = state
        self.parent = parent
        self.action_taken = action_taken

    def actions(self, state):
        # Depending on state, what actions can I take?
        pass

    def result(self, state, action):
        # What result would I get based on the action taken?
        pass

    def goal_test(self, state):
        # Does my current state meet the goal?
        pass

    def calculate_location(self):
        return tuple((self.state.taxi_row, self.state.taxi_col))


def encode(taxi_row, taxi_col, pass_loc, dest_idx):
    # (5) 5, 5, 4
    i = taxi_row
    i *= 5
    i += taxi_col
    i *= 5
    i += pass_loc
    i *= 4
    i += dest_idx
    return i

def convert_destination(destination):
    if destination == 0:
        return tuple((0, 0))
    if destination == 1:
        return tuple((0, 4))
    if destination == 2:
        return tuple((4, 0))
    if destination == 3:
        return tuple((4, 3))

# RESULTS given from this function
def expand(node, env):
    children = []

    current_state = node.state

    for i in range(len(node.state.actions)):
        # If valid action
        if node.state.actions[i] != 0:

            # Move South
            if i == 0:
                # add to row
                new_observation = encode(node.state.taxi_row + 1, node.state.taxi_col, node.state.passenger, node.state.destination)
                new_actions = env.unwrapped.action_mask(new_observation)
                new_state = State(node.state.taxi_row + 1, node.state.taxi_col, node.state.passenger, node.state.destination, new_actions)
                child_node = Node(new_state, parent=node, action_taken=i)
                children.append(child_node)
                continue

            # Move North
            if i == 1:
                # subtract from row
                new_observation = encode(node.state.taxi_row - 1, node.state.taxi_col, node.state.passenger, node.state.destination)
                new_actions = env.unwrapped.action_mask(new_observation)
                new_state = State(node.state.taxi_row - 1, node.state.taxi_col, node.state.passenger, node.state.destination, new_actions)
                child_node = Node(new_state, parent=node, action_taken=i)
                children.append(child_node)
                continue

            # Move East
            if i == 2:
                # add to column
                new_observation = encode(node.state.taxi_row, node.state.taxi_col + 1, node.state.passenger, node.state.destination)
                new_actions = env.unwrapped.action_mask(new_observation)
                new_state = State(node.state.taxi_row, node.state.taxi_col + 1, node.state.passenger, node.state.destination, new_actions)
                child_node = Node(new_state, parent=node, action_taken=i)
                children.append(child_node)
                continue

            # Move West
            if i == 3:
                # subtract from column
                new_observation = encode(node.state.taxi_row, node.state.taxi_col - 1, node.state.passenger, node.state.destination)
                new_actions = env.unwrapped.action_mask(new_observation)
                new_state = State(node.state.taxi_row, node.state.taxi_col - 1, node.state.passenger, node.state.destination, new_actions)
                child_node = Node(new_state, parent=node, action_taken=i)
                children.append(child_node)
                continue

            # TODO: Possible errors in the two if statements below.
            # TODO: Need to handle picking/dropping the passenger.
            # Pick up passenger if passenger isnt already picked up.
            if i == 4 and node.state.passenger != 4:
                # pick up passenger 
                pass

            # Drop off passnger if at correct location.
            if i == 5 and node.state.passenger == 4:
                # drop off passenger
                pass 

    return children


def dls(node, goal, limit, env):
    #print("node location: {} Goal: {}".format(node.calculate_location(), goal))
    if limit < 0:
        return None # Depth limit exceeded. return None.
    
    # This is GOAL-TEST
    if node.calculate_location() == goal:
        actions_taken = []
        current_node = node

        while current_node.parent != None:
            actions_taken.append(current_node.action_taken)
            current_node = current_node.parent

        #print("Node {} was successful".format(node))
        actions_taken.reverse()
        #print("Actions taken: ", actions_taken)
        return tuple((actions_taken, node)) # Goal state found. Return the list of actions it took to get there.
    
    if limit == 0:
        return None # Depth limit reached. Return None.
    
    children = expand(node, env)

    for child in children:
        result = dls(child, goal, limit -1, env)
        if result is not None:
            return result

    return None




def create_agent():

    # Create environment
    env = gym.make('Taxi-v3')
    #env = gym.make('Taxi-v3', render_mode="human")

    # Start of episode
    observation, info = env.reset()
    total_reward = 0
    taxi_row, taxi_col, passenger, destination = env.unwrapped.decode(observation)
    actions = info['action_mask']
    my_state = State(taxi_row, taxi_col, passenger, destination, actions)
    my_node = Node(my_state, None, None)

    print("Row: {} Col: {} Passenger: {} Destination: {}".format(my_state.taxi_row, my_state.taxi_col, my_state.passenger, my_state.destination))
    print("Available actions: {}".format(my_state.actions))

    print("DlS-ing...")
    path_to_passenger = dls(my_node, convert_destination(passenger), 8, env)
    #print("path_to_passenger: ", path_to_passenger[0])
    path_to_passenger[0].append(4)
    path_to_destination = dls(path_to_passenger[1], convert_destination(destination), 8, env)
    #print("path_to_destination: ", path_to_destination[0])
    path_to_destination[0].append(5)
    actions_to_be_taken = path_to_passenger[0] + path_to_destination[0][len(path_to_passenger[0])-1:]
    print("actn_2b_taken: ", actions_to_be_taken)

    for action in actions_to_be_taken:
        observation, reward, terminated, truncated, info = env.step(action)
        total_reward += reward


    #print('observation: ', observation)
    #print('info: ', info)
    # End episode
    env.close()
    return total_reward