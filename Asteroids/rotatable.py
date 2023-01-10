import movable
import math

class Rotatable(movable.Movable):
    def __init__(self, x, y, dx, dy, r, w, h):
        movable.Movable.__init__(self, x, y, dx, dy, w, h)
        #self.mX = x
        #self.mY = y
        #self.mDX = dx
        #self.mDY = dy
        #self.mWorldWidth = w
        #self.mWorldHeight = h
        self.mRotation = r
        #print('width = ' + str(self.mWorldWidth))
        #print('height = ' + str(self.mWorldHeight))
        #print('rotation = ' + str(self.mRotation))

    def getRotation(self):
        return self.mRotation

    def rotate(self,delta_rotation):
        new_r = self.mRotation + delta_rotation
        if new_r >= 360:
            new_r -= 360
        if new_r < 0:
            new_r += 360
        self.mRotation = new_r

    def splitDeltaVIntoXAndY(self,rotation,delta_velocity):
        x = delta_velocity * (math.cos(math.radians(rotation)))
        y = delta_velocity * (math.sin(math.radians(rotation)))
        ye = (x,y)
        return ye


    def accelerate(self,delta_velocity):
        bruh = self.splitDeltaVIntoXAndY(self.mRotation,delta_velocity)
        self.mDX += bruh[0]
        self.mDY += bruh[1]
        #print('mdy movable = '+str(self.mDY))
        #print('mdy movable = ' + str())
        #print('mdy original = '+str(self.mDY))
        #print('mdx original = '+str(self.mDX))
        return

    def rotatePoint(self,x,y):
        r = math.sqrt((x**2) + (y**2))
        theta = math.atan2(y,x)
        newt = theta + math.radians(self.mRotation)
        xone = r * math.cos(newt)
        yone = r * math.sin(newt)
        koji = (xone,yone)
        return koji

    def translatePoint(self,x,y):
        x += self.mX
        y += self.mY
        return (x,y)

    def rotateAndTranslatePoint(self,x,y):
        (x,y) = self.rotatePoint(x,y)
        (x,y) = self.translatePoint(x,y)
        theo = (x,y)
        return theo

    def rotateAndTranslatePointList(self,points):
        ye = []
        for t in points:
            #print('x = ' + str(t[0]))
            #print('y = ' + str(t[1]))
            t = self.rotateAndTranslatePoint(t[0],t[1])
            ye.append(t)
        #print(ye)
        return ye



