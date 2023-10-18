import agent1
import policy_search

# Availabe functions to call
available_functions = ["Generate Default Policy", "Process Policy", "Run Agent"]
text_break = "-------------------------------"

# Nice print message
def select_print(func_num):
    print("SELECTED: '{}'.".format(available_functions[func_num]))

def run_script(function_type):
    select_print(function_type)

    # Handle Generate Random Policy
    if function_type == 0:
        size = int(input("--> Size of Array: "))
        policy_search.write_policy(policy_search.default_policy(size))
        print("Policy Generated: {}".format(policy_search.decode_policy()))

    # Handle Process Policy
    if function_type == 1:
        print("god damn n words")
        iterations = int(input("--> Iterations: "))
        policy_search.process_policy()

    # Handle Run Agent
    if function_type == 2:
        iterations = int(input("--> Iterations: "))
        render = int(input("0 = default, 1 = human\n--> Render Mode: "))

        total = 0
        for i in range(0, iterations):
            total += agent1.create_agent(render)

        print('Average Score: ', total / iterations)

def main():
    print(text_break)
    for i in range(len(available_functions)):
        print(str(i) + ": " + available_functions[i] ) 

    function_type = int(input("{}\n--> Please choose a function: ".format(text_break)))

    run_script(function_type)

if __name__ == "__main__":
    main()
