import rotatable
import math
import random
import pygame

class Polygon(rotatable.Rotatable):
    def __init__(self, x, y, dx, dy, r, w, h):
        rotatable.Rotatable.__init__(self, x, y, dx, dy, r, w, h)
        #self.mX = x
        #self.mY = y
        #self.mDX = dx
        #self.mDY = dy
        #self.mWorldWidth = w
        #self.mWorldHeight = h
        #self.mRotation = r
        self.mColor = (255,255,255)
        self.mOriginalPolygon = []

    def getPolygon(self):
        return self.mOriginalPolygon
    def getColor(self):
        return self.mColor
    def getRadius(self):
        total = 0
        num = []
        ans = 0
        rad = 0
        othertotal = 0
        for point in self.mOriginalPolygon:
            one = (point[0] - 0)**2
            two = (point[1] - 0)**2
            ans = one + two
            ans = abs(math.sqrt(ans))
            num.append(ans)
            #print('x = ' + str(self.mX))
            #print('y = ' + str(self.mY))
            #print('point[0] = ' + str(point[0]))
            #print('point[1] = ' + str(point[1]))
            #print('one = ' + str(one))
            #print('two = ' + str(two))
        if len(num) == 0:
            return 0
        else:
            return sum(num) / len(num)


            ##num += 1
            #xtwo = point[0]
            #ytwo = point[1]
            #print('xtwo = ' + str(xtwo))
            #print('ytwo = ' + str(ytwo))

            #inside = ((self.mX - xtwo)**2) + ((self.mY - ytwo)**2)
            #rad = math.sqrt(inside)
            #total += rad

#need to find the average of the distances.
#probably have to use the absolute value which is abs().
#maybe take the original total - the average total?
        #ans = total / num
        #print('num = ' + str(num))
        #print('total = ' + str(total))
        #print(rad)
        #print(ans)
        #return ans

    def setPolygon(self,points):
        #possible error where points list is not valid?
        if points == []:
            self.mOriginalPolygon = []
        else:
            for t in points:
                    self.mOriginalPolygon.append(t)
            return

    def setColor(self,color):
        self.mColor = color
        return

    def draw(self,surface):
        pygame.draw.polygon(surface,self.mColor,self.rotateAndTranslatePointList(self.mOriginalPolygon),0)
        return
