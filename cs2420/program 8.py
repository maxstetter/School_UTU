import math
import time

class Student:
    def __init__(self, last_name, first_name, SSN, email, age):
        self.mLast_Name = last_name
        self.mFirst_Name = first_name
        self.mSSN = SSN
        self.mEmail = email
        self.mAge = age



    def __gt__(self, other):
        if ( self.mSSN > other ):
            return True
        else:
            return False

    def __lt__(self, other):
        if ( self.mSSN < other ):
            return True
        else:
            return False

    def __eq__(self, other):
        if ( self.mSSN == other ):
            return True
        else:
            return False

    def __ne__(self, other):
        if self.mSSN != other:
            return True
        else:
            return False

    def __int__(self):
        return int(self.mSSN.replace('-',''))



    def getLastName(self):
        return self.mLast_Name

    def getFirstName(self):
        return self.mFirst_Name

    def getSSN(self):
        return self.mSSN

    def getEmail(self):
        return self.mEmail

    def getAge(self):
        return self.mAge

class Node:
    def __init__(self, item):
        self.mItem = item
        self.mL = None
        self.mR = None

###########
def IsPrime(x):
    s = int( math.sqrt(x) )
    for i in range( 2, s + 1 ):
        if x % i == 0:
            return False
    return True


class UUC:
    def __init__(self, neededSize):
        actualSize = 2 * neededSize + 1
        while not IsPrime(actualSize):
            actualSize += 2
        self.mTable = []
        for i in range(actualSize):
            self.mTable.append(None)

        self.mRoot = None
        self.mCount = 0
        self.mDupe = 0


        self.mSize = 0
        #pass

    def Dupe(self):
        return self.mDupe

    def Size(self): #return
        return self.mCount

    def Insert(self, item): #return false on duplicates.
        if self.Exists(item):
            self.mDupe += 1
            return False
        key = int(item)
        index = key % len(self.mTable)
        while self.mTable[index]:
            index += 1
            if index >= len(self.mTable):
                #index = 0
                index -= len(self.mTable)
        self.mTable[index] = item
        self.mSize += 1
        return True


    def Delete(self, item): #return False if can't find.
        if not self.Exists(item):
            return False
        key = int(item)
        index = key % len(self.mTable)
        while not (self.mTable[index] and self.mTable[index] == item):
            index += 1
            if index >= len(self.mTable):
                #index = 0
                index -= len(self.mTable)
        self.mTable[index] = False
        self.mSize -= 1
        return True



    def Retrieve(self, item):
        if not self.Exists(item):
            return None
        key = int(item)
        index = key % len(self.mTable)
        while True:
            if self.mTable and self.mTable[index] == item:
                return self.mTable[index]
            index += 1
            if index >= len(self.mTable):
                index = 0


    def Exists(self, item):
        key = int(item)
        index = key % len(self.mTable)
        while True:
            if self.mTable[index] is None:
                return False
            if self.mTable[index] and self.mTable[index] == item:
                return True
            index += 1
            if index >= len(self.mTable):
                #index = 0
                index -= len(self.mTable)


    def Traverse(self, callbackFunction):
        #iterate through the entire list. if item != none, check if it is equal to item.
        for i in self.mTable:
            if i:
                callbackFunction(i)



    def Size(self): #return
        return self.mSize

gTotalAge = 0
def AddAges(item):
    global gTotalAge
    gTotalAge += int(item.getAge())


def main():
    global gTotalAge
    uuc = UUC(300000)

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
        s = Student( "", "", ssn, "", "0" )
        if not uuc.Delete(s):
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
        ssn = line.strip()
        s = Student( "", "", ssn, "", "0" )
        student = uuc.Retrieve(s)
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

main()


