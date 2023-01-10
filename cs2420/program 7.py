from program4 import Student
import time

class Node:
    def __init__(self, item):
        self.mItem = item
        self.mL = None
        self.mR = None

###########
class UUC:
    def __init__(self):
        self.mRoot = None
        self.mCount = 0
        self.mDupe = 0

        #pass
    def Insert(self, item): #return false on duplicates.
        if self.Exists(item):
            self.mDupe += 1
            return False
        n = Node(item)
        self.mRoot = self.InsertR( n, self.mRoot )
        self.mCount +=1
        return True

    def InsertR(self, n, current):
        if current is None:
            current = n
        elif n.mItem < current.mItem:
            current.mL = self.InsertR(n, current.mL)
        else:
            current.mR = self.InsertR(n, current.mR)
        return current

    def Delete(self, item): #return False if can't find.
        if not self.Exists(item):
            return False
        self.mRoot = self.DeleteR(item, self.mRoot)
        self.mCount -= 1
        return True

    def DeleteR( self, item, current ):
        if item < current.mItem:
            current.mL = self.DeleteR(item, current.mL)
        elif item > current.mItem:
            current.mR = self.DeleteR( item, current.mR )
        else: # current is point to the node with the item to be deleted.
            #case 1: current has no children
            if current.mL is None and current.mR is None:
                current = None
            #case 2a: current has 1 right child.
            elif current.mL is None and current.mR is not None:
                current = current.mR
            #case 2b: current has 1 left child.
            elif current.mR is None:
                current = current.mL
            #case 3: current has 2 children
            else:
                successor = current.mR
                while successor.mL is not None:
                    successor = successor.mL
                current.mItem = successor.mItem
                current.mR = self.DeleteR(successor.mItem, current.mR)
        return current
    #3/29 - 48 min
    def Retrieve(self, item):
        return self.RetrieveR(item, self.mRoot )

    def RetrieveR(self, item, current): #return None if can't find.
        if current is None:
            return None
        elif current.mItem == item:
            return current.mItem
        elif item < current.mItem:
            return self.RetrieveR(item, current.mL)
        else:
            return self.RetrieveR(item, current.mR)

    #3/29 - 37 min
    def Exists(self, item):
        return self.ExistsR( item, self.mRoot )

    def ExistsR(self, item, current):
        if current is None:
            return False
        elif current.mItem == item:
            return True
        elif item < current.mItem:
            return self.ExistsR(item, current.mL)
        else:
            return self.ExistsR(item, current.mR)

    def Dupe(self):
        return self.mDupe

    def Size(self): #return
        return self.mCount

    def Traverse(self, callbackFunction):
        t2 = time.time()
        self.TraverseR(callbackFunction, self.mRoot)
        print("Traverse Time: {}".format(t2))

    def TraverseR(self, callbackFunction, current):
        if current is None:
            return
        callbackFunction(current.mItem)
        self.TraverseR(callbackFunction, current.mL)
        self.TraverseR(callbackFunction, current.mR)

gTotalAge = 0
def AddAges(item):
    global gTotalAge
    gTotalAge += int(item.getAge())



def main():
    global gTotalAge
    uuc = UUC()

    #insert code
    t1 = time.time()
    f = open("InsertNamesMedium.txt", "r")
    for line in f:
        words = line.split()
        s = Student(words[0], words[1], words[2], words[3], words[4])
        uuc.Insert(s)

    print("Insert Time: {}".format(t1))
    print("Insert error count: {}".format(uuc.Dupe()))
    f.close()



                            #traverse code
    uuc.Traverse(AddAges)
    print("The average age is", gTotalAge / uuc.Size() )




                            #delete code
    t3 = time.time()
    fin = open("DeleteNamesMedium.txt", "r")
    delete_count = 0

    for line in fin:
        ssn = line.strip()
        #s = Student( "", "", ssn, "", "0" )
        if not uuc.Delete(ssn):
            delete_count += 1
    print("Delete error count: {}".format(delete_count))
    print("Delete Time: {}".format(t3))
    fin.close()

                            #retrieve code

    f = open('RetrieveNamesMedium.txt', 'rt')
    retrieve_time = time.time()
    ravg_age = 0
    retrieves = 0
    fails = 0
    for line in f:
        line = line.strip()
        student = uuc.Retrieve(line)
        if student is None:
            fails += 1
            continue
        ravg_age += int(student.getAge())
        retrieves += 1
    f.close()
    ravg_age /= float(retrieves)
    print("retrieve failures: {}".format(fails))
    print("Average age of retrieved students is:" + str(ravg_age))
    print("retrievetime {}".format(retrieve_time))

"""
    t4 = time.time()

    totalRetrieveAge = 0
    totalRetrieveCount = 0
    #check zoom 3/31/21 for instructions.
    fint = open("RetrieveNames.txt", "r")
    retrieve_count = 0
    #use this retrieve code again for delete. see 3/31/21
    for line in fint:
        ssn = line.strip()
        s = uuc.Retrieve(ssn)
        #s = Student( "", "", ssn, "", "0" )
        #s2 = uuc.Retrieve(s)
        if s is None:
            retrieve_count += 1
            #count how many errors there are instead of printing the below statement.
            #print("retrieve error count: {}".format(retrieve_count))
        else:
            totalRetrieveAge += int(s.GetAge())
            totalRetrieveCount += 1
    print("retrieve error count: {}".format(retrieve_count))
    print( "Average age of retrieved students is: ".format(totalRetrieveAge/uuc.Size()))
    print("Retrieve Time: {}".format(t4))
    fint.close()
"""
main()

