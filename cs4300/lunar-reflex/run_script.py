import agent1
import agent2
import agent3

def run_script(iterations, agent_number):
    print('Running ' + str(iterations) + ' iterations on agent ' + str(agent_number) + '...')

    total = 0
    for i in range(0, iterations):
        if agent_number == 1:
            total += agent1.create_agent()
        elif agent_number == 2:
            total += agent2.create_agent()
        elif agent_number == 3:
            total += agent3.create_agent()
        else:
            print('INVALID AGENT')

    print('Average Score: ', total / iterations)


def main():
    iterations = int(input("Iterations: "))
    agent = int(input("which agent: "))

    run_script(iterations, agent)

if __name__ == "__main__":
    main()
