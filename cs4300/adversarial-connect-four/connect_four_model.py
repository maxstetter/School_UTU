#!/usr/bin/env python3

import numpy as np
import copy

class ConnectFour:
    """
    Class to support search for the connect_four PettingZoo environment.
    """

    def __init__(self):
        self.board = [0] * (6 * 7)
        self.agents = ["player_0", "player_1"]
        self.possible_agents = self.agents[:]
        self.terminations = None
        self.winner = -1
        self.current_agent = 0
        return

    def copy_from_env(self, env):
        self.board = copy.deepcopy(env.unwrapped.board)
        self.agents = self.possible_agents[:]
        self.current_agent = env.unwrapped.agents.index(env.unwrapped.agent_selection)
        self.terminations = copy.deepcopy(env.unwrapped.terminations)
        self.winner = -1
        for agent in env.unwrapped.rewards:
            if env.unwrapped.rewards[agent] > 0:
                self.winner = env.unwrapped.agents.index(agent)
        return

    def legal_moves(self):
        return [i for i in range(7) if self.board[i] == 0]

    def game_over(self):
        return self.terminations[self.agents[self.current_agent]]

    def reset(self):
        self.board = [0] * (6 * 7)
        self.agents = self.possible_agents[:]
        self.current_agent = 0
        self.terminations = {i: False for i in self.agents}
        self.winner = -1
        return

    def step(self, action):
        if self.terminations[self.agents[self.current_agent]]:
            return
        
        # assert valid move
        # make sure the top row of the action column is unplayed
        assert self.board[0:7][action] == 0, "played illegal move."

        piece = self.current_agent + 1
        for i in list(filter(lambda x: x % 7 == action, list(range(41, -1, -1)))):
            if self.board[i] == 0:
                self.board[i] = piece
                break

        next_agent = (self.current_agent + 1) % 2

        winner = self.check_for_winner()

        # check if there is a winner
        if winner:
            self.winner = self.current_agent
            self.terminations = {i: True for i in self.agents}
        # check if there is a tie
        elif all(x in [1, 2] for x in self.board):
            # once either play wins or there is a draw, game over, both players are done
            self.terminations = {i: True for i in self.agents}

        self.current_agent = next_agent

        return


    def check_for_winner(self):
        board = np.array(self.board).reshape(6, 7)
        piece = self.current_agent + 1

        # Check horizontal locations for win
        column_count = 7
        row_count = 6

        for c in range(column_count - 3):
            for r in range(row_count):
                if (
                    board[r][c] == piece
                    and board[r][c + 1] == piece
                    and board[r][c + 2] == piece
                    and board[r][c + 3] == piece
                ):
                    return True

        # Check vertical locations for win
        for c in range(column_count):
            for r in range(row_count - 3):
                if (
                    board[r][c] == piece
                    and board[r + 1][c] == piece
                    and board[r + 2][c] == piece
                    and board[r + 3][c] == piece
                ):
                    return True

        # Check positively sloped diagonals
        for c in range(column_count - 3):
            for r in range(row_count - 3):
                if (
                    board[r][c] == piece
                    and board[r + 1][c + 1] == piece
                    and board[r + 2][c + 2] == piece
                    and board[r + 3][c + 3] == piece
                ):
                    return True

        # Check negatively sloped diagonals
        for c in range(column_count - 3):
            for r in range(3, row_count):
                if (
                    board[r][c] == piece
                    and board[r - 1][c + 1] == piece
                    and board[r - 2][c + 2] == piece
                    and board[r - 3][c + 3] == piece
                ):
                    return True

        return False

    def __str__(self):
        s = ""
        s += "+" + "---+"*7
        for row in range(6):
            line = "|"
            for col in range(7):
                i = row*7+col
                c = " {} |".format(self.board[i])
                line += c
            s += "\n" + line
            s += "\n" + "+" + "---+"*7
        return s

def test_copy_env():
    from pettingzoo.classic import connect_four_v3
    # import random
    env = connect_four_v3.env(render_mode=None)
    env.reset()
    for action in [0, 1, 2, 3, 4, 5, 6, 0, 1, 2, 3, 4, 5, 6]:
        env.step(action)
    env1 = ConnectFour()
    env1.copy_from_env(env)
    print(env1.board)
    print(env1.current_agent)
    print(env1.winner)

    print()
    print()
    print()
    for action in [0, 1, 0, 1, 0, 1, 2, 1]:
        env.step(action)
    env1 = ConnectFour()
    env1.copy_from_env(env)
    print(env1.board)
    print(env1.current_agent)
    print(env1.winner)
    return

def test_legal_actions():
    env1 = ConnectFour()
    env1.reset()
    while not env1.game_over():
        actions = env1.legal_moves()
        print(actions)
        env1.step(actions[0])
    return

def test():
    env1 = ConnectFour()
    env1.reset()
    for action in [6, 1, 6, 1, 6, 1, 6, 1]:
        env1.step(action)
    print(env1.board)
    print(env1.current_agent)
    print(env1.winner)
    
    
    return

if __name__ == "__main__":
    # test_copy_env()
    test_legal_actions()
    # test()
    
