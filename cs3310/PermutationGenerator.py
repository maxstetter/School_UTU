# Max Stetter

def createlist(n):
    lst = []
    for i in range (n):
        lst.append(i+1)
    return (lst)
    

def PermutationGenerator(lst):
    if len(lst) == 0:
        return []
    if len(lst) == 1:
        return [lst]
    newlist = []
    for i in range(len(lst)):
       x = lst[i]
       lst1 = lst[:i] + lst[i+1:]
       for y in PermutationGenerator(lst1):
           newlist.append([x] + y)
    return newlist
 
 
def main():
    getter = int(input("List Length?"))
    lst = createlist(getter)
    for i in PermutationGenerator(lst):
        print(i)
    
main()
