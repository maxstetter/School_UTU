import agent1
import policy_search
import policy_search

# Availabe functions to call
available_functions = ["Process Policy", "Run Agent"]
text_break = "-------------------------------"

# Nice print message
def select_print(func_num):
    print("SELECTED: '{}'.".format(available_functions[func_num]))

def run_script(function_type):
    select_print(function_type)

    # Handle Process Policy
    if function_type == 0:
        iterations = int(input("--> Iterations: "))
        policy_search.process_policy(iterations)

    # Handle Run Agent
    if function_type == 1:
        iterations = int(input("--> Iterations: "))
        render = int(input("0 = default, 1 = human\n--> Render Mode: "))

        total = 0
        total += agent1.create_agent(render, iterations)

        print('Average Score: ', total / iterations)

def main():
    print(text_break)
    for i in range(len(available_functions)):
        print(str(i) + ": " + available_functions[i] ) 

    function_type = int(input("{}\n--> Please choose a function: ".format(text_break)))

    run_script(function_type)

if __name__ == "__main__":
    main()
