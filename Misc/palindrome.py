def palindrome(word):
    reverse = word[::-1]
    if (reverse == word):
        print("true")
    else:
        print("false")

def main():
    word = input("enter word: ")
    palindrome(word)
    
main()