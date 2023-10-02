#!/usr/bin/env python3

from gymnasium.envs.registration import register

for rooms in range(2, 10):
    for size in range(4, 10):
        register(
            id="MiniGrid-MultiRoom-N{}-S{}-v0".format(rooms, size),
            entry_point="minigrid.envs:MultiRoomEnv",
            kwargs={"minNumRooms": rooms, "maxNumRooms": rooms, "maxRoomSize": size},
        )
