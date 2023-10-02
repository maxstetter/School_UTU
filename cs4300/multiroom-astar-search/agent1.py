import gymnasium as gym
import my_minigrids
import random
from minigrid.wrappers import FullyObsWrapper
import queue
import numpy

# Create node class
class Node:
    def __init__(self, col, row, obj_type=None, direction=None, actions=[], parent=None, action_taken=None):
        self.col = col
        self.row = row
        self.position = (col, row) # Position of the arrow.
        self.direction = direction # Direction of the arrow.
        self.actions = actions # ACTION(s) NOT USED
        self.parent = parent # parent node.
        self.action_taken = action_taken # Action taken previously. NOT USED
        self.obj_type = obj_type # The type of object. (wall/door etc.)

        self.cost = 0 # cost from start node to this node.
        self.heuristic = 0 # estimated cost from this node to goal.
        self.total = 0 # cost + heuristic.

    def __lt__(self, other):
        return self.total < other.total

    def set_direction(self, direction):
        self.direction = direction

# Get the agent coordinates based on entire grid.
def find_agent(image):
    width, height, forgot = image.shape
    for c in range(width):
        for r in range(height):
            if image[c, r, 0] == 10:
                return (c, r)

# Get the goal coordinates based on entire grid.
def find_goal(image):
    width, height, forgot = image.shape
    for c in range(width):
        for r in range(height):
            if image[c, r, 0] == 8:
                return (c, r)

# A* search
def astar(grid, start_node, goal_node):
    open_set = queue.PriorityQueue()
    closed_set = set()

    open_set.put(start_node)

    while not open_set.empty():
        current_node = open_set.get()

        if current_node.position == goal_node.position:
            path = []
            coords_path = []
            while current_node:
                path.append(current_node)
                coords_path.append(current_node.position)
                current_node = current_node.parent
            print("coords_path: ", coords_path[::-1])
            return path[::-1]  # Reverse the path to get it from start to goal

        closed_set.add(current_node.position)

        for neighbor in get_neighbors(grid, current_node):
            if neighbor.position in closed_set:
                continue

            tentative_score = current_node.cost + 1  # Assuming each step has a cost of 1

            if neighbor not in open_set.queue or tentative_score < neighbor.cost:
                neighbor.cost = tentative_score
                neighbor.heuristic = heuristic(neighbor.position, goal_node.position)
                neighbor.total = neighbor.cost + neighbor.heuristic
                neighbor.parent = current_node

                if neighbor not in open_set.queue:
                    open_set.put(neighbor)

    return None  # No path found

def heuristic(pos1, pos2):
    # Example heuristic: Manhattan distance
    return abs(pos1[0] - pos2[0]) + abs(pos1[1] - pos2[1])

def get_neighbors(grid, node):
    width, height, forgot = grid.shape
    neighbors = []
    directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]

    for dc, dr in directions:
        c, r = node.position[0] + dc, node.position[1] + dr

        # Verify coordinates are inside the whole grid.
        if 0 <= c < width and 0 <= r < height:
            
            # Get the item from index.
            item = grid[c, r, 0]

            # Handle empty
            if item == 1:
                new_node = Node(c, r, 1, parent=node)
                new_node.set_direction(convert_direction(find_direction_to(node, new_node)))
                neighbors.append(new_node)

            # Handle wall
            if item == 2:
                pass

            # Handle door
            if item == 4:
                new_node = Node(c, r, 4, parent=node)
                new_node.set_direction(convert_direction(find_direction_to(node, new_node)))
                neighbors.append(new_node)

            # Handle agent
            if item == 10:
                new_node = Node(c, r, 10, parent=node)
                new_node.set_direction(convert_direction(find_direction_to(node, new_node)))
                neighbors.append(new_node)
            
            # Handle goal 
            if item == 8:
                new_node = Node(c, r, 8, parent=node)
                new_node.set_direction(convert_direction(find_direction_to(node, new_node)))
                neighbors.append(new_node)

    return neighbors

# Calculate shortest turn path. Takes desired direction and current direction. Returns list of turns to take.
def calculate_turn(desired, current):
    turns = []

    # Handle Up
    if desired == 3:
        if current == 0:
            turns.append(0)
        if current == 1:
            turns.append(0)
            turns.append(0)
        if current == 2:
            turns.append(1)
    
    # Handle Down
    if desired == 1:
        if current == 0:
            turns.append(1)
        if current == 2:
            turns.append(0)
        if current == 3:
            turns.append(1)
            turns.append(1)

    # Handle Right
    if desired == 0:
        if current == 3:
            turns.append(1)
        if current == 2:
            turns.append(0)
            turns.append(0)
        if current == 1:
            turns.append(0)

    # Handle Left
    if desired == 2:
        if current == 3:
            turns.append(0)
        if current == 0:
            turns.append(0)
            turns.append(0)
        if current == 1:
            turns.append(1)
    
    return turns

# Convert text direction to int. Returns int
def convert_direction(position):
    if position == "right":
        return 0
    if position == "left":
        return 2
    if position == "up":
        return 3
    if position == "down":
        return 1
    

# Orient agent to face the correct way
def orient_agent(desired, current):
    if current == None:
        print('none direction')
        return []
    if desired == "right":
        return calculate_turn(0, current)
    if desired == "left":
        return calculate_turn(2, current)
    if desired == "up":
        return calculate_turn(3, current)
    if desired == "down":
        return calculate_turn(1, current)

# Takes two nodes and finds the direction from one to the other returned as a string.
def find_direction_to(node1, node2):

    # Find the position difference 
    position_diff = tuple(numpy.subtract(node1.position, node2.position))

    # Handle right
    if position_diff[0] < 0:
        position = "right"

    # Handle left
    if position_diff[0] > 0:
        position = "left"

    # Handle up
    if position_diff[1] > 0:
        position = "up"

    # Handle down
    if position_diff[1] < 0:
        position = "down"

    # Handle no difference
    if position_diff[0] == position_diff[1]:
        position = "same"

    return position


# Find the action(s) taken inbetween two nodes.
def find_actions(current, next):
    actions = []

    position = find_direction_to(current, next)
    
    turns = orient_agent(position, current.direction)
    for turn in turns:
        actions.append(turn)

    # Handle Agent
    if next.obj_type == 10:
        print("Thats me dude...")

    # Handle door square. open it and move forward
    if next.obj_type == 4:
        print('I found me a door...')
        actions.append(5)

    # Handle empty square/goal move into it.
    if next.obj_type == 1 or 8:
        print("Empty...")
        actions.append(2)
    

    return actions


# Evaluate the path in order to get the actions. Returns a list of actions to take.
def evaluate_path(path):
    actions = []

    # Iterate over each node in the path.
    for i in range(len(path) -1):
        current = path[i] # Current node.
        next = path[i + 1] # Next node.
        
        # Get the actions it took to get from current to next.
        found = find_actions(current, next)
        for action in found:
            actions.append(action)
        
    return actions

# Main function that creates the agent and environment.
def create_agent():

    # Create environment
    env = gym.make('MiniGrid-MultiRoom-N2-S4-v0')
    #env = gym.make('MiniGrid-MultiRoom-N6-S6-v0', render_mode="human")
    #env = gym.make('MiniGrid-MultiRoom-N2-S4-v0', render_mode="human")
    env = FullyObsWrapper(env)

    # Start of episode
    observation, info = env.reset()
    total_reward = 0
    image = observation['image']
    direction = observation['direction']

    agent_coord = find_agent(image)
    goal_coord = find_goal(image)
    print('Agent coordinates: ', agent_coord)
    print('Goal coordinates: ', goal_coord)
    print('Direction: ', direction)
    start_node = Node(agent_coord[0], agent_coord[1], 10, direction)
    goal_node = Node(goal_coord[0], goal_coord[1], 8)

    astar_path = astar(image, start_node, goal_node)
    #print("astar_path: ", astar_path)

    actions_to_be_taken = evaluate_path(astar_path)
    print("actions_to_be_taken: ", actions_to_be_taken)

    #while 0 != True:
    #    env.render()

    for action in actions_to_be_taken:
        observation, reward, _, _, info = env.step(action)
        total_reward += reward


    # End episode
    env.close()
    return total_reward