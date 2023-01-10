

def getUserChoice(prompt):
    invalid = True
    while invalid:
        response = input(prompt).strip()
        if response != "":
            invalid = False
        else:
            print("Invalid response.")
    return response

print("Returned: ", repr(getUserChoice("What is my name? \n")))