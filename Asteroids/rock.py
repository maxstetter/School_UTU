import polygon
import random
import math

class Rock(polygon.Polygon):
    def __init__(self,x,y,w,h):

        dx = 0
        dy = 0
        self.mSpinRate = random.uniform(-90.0,90.0)
        #self.setSpinRate(random.uniform(-90.0,90.0))
        self.mOriginalPolygon = []
        r = random.uniform(0.0, 359.9)

        polygon.Polygon.__init__(self, x, y, dx, dy, r, w, h)

        chaboi = random.randrange(10, 20)
        ran = self.createRandomPolygon(random.randrange(20,30),random.randrange(5,8))
        self.setPolygon(ran)
        self.accelerate(chaboi)
        #r = random.uniform(0.0, 359.9)


    def getSpinRate(self):
        return self.mSpinRate

    def setSpinRate(self,spin_rate):
        self.mSpinRate = spin_rate
        return

    def createRandomPolygon(self,radius,number_of_points):
        new_list = []
        r = (random.random() * 0.6 + 0.7) * radius
        i = 0
        for p in range(number_of_points):
            i+=1
            theta = (i*360)/number_of_points
            thetar = math.radians(theta)
            x = math.cos(thetar) * r
            y = math.sin(thetar)* r
            new_list.append((x,y))
        return new_list

    def evolve( self, dt ):
        self.rotate(self.mSpinRate * dt)
        self.move(dt)
        #print('spin rate = ' + str(self.getSpinRate()))
        #self.rotate(self.mSpinRate * dt)
        #print('before rotation = ' + str(self.getRotation()))
        #self.mRotation = ( self.mRotation + self.mSpinRate * dt ) % 360
        #print('rotation = ' + str(self.getRotation()))
        return

    # self.mX = x
    # self.mY = y
    # self.mDX = 0
    # self.mDY = 0
    # self.mWorldWidth = w
    # self.mWorldHeight = h
    # self.mRotation = random.uniform(0.0,359.9)
    # self.mColor = (255,255,255)
    # self.mSpinRate = 0
    # chaboi = random.randrange(10,20)
    # self.mOriginalPolygon = self.createRandomPolygon(chaboi,random.randrange(5,8))
    # self.accelerate(random.randrange(10,21))