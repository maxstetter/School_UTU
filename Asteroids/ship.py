import polygon
import pygame
import movable
import bullet
import math

class Ship(polygon.Polygon):
    def __init__(self,x,y,w,h):
        #have theo help with the unit tests
        ### Used to center Ship
        ###x = 450
        ###y = 450
        leftp = (30,0)
        rightp = (0,- 10)
        bottomp = (0,10)
        #self.mOriginalPolygon = [(450,450)]

        dx = 0
        dy = 0
        r = 0

        #polygon.Polygon.setPolygon(self,(leftp,rightp,bottomp))
        polygon.Polygon.__init__(self, x, y, dx, dy, r, w, h)
        #self.mOriginalPolygon = [(450, 450)]
        self.setPolygon((leftp, rightp, bottomp))

        #self.mX = x
        #self.mY = y
        #self.mDX = 0
        #self.mDY = 0
        #self.mWorldWidth = w
        #self.mWorldHeight = h
        #self.mRotation = 0
        #self.mColor = (255,255,255)

        #leftp = (((450) - 10),450)
        #rightp = (((450) + 10),450)
        #bottomp = ((450),450 + 40)
        #polygon.Polygon.setPolygon()

    def fire(self):
        x = self.rotateAndTranslatePoint(self.mOriginalPolygon[0][0],self.mOriginalPolygon[0][1])

        #x = self.mOriginalPolygon[2]
        #print('x = ' + str(x))
        print('mX = ' + str(self.mX))
        print('mY = ' + str(self.mY))
        print('mDX = ' + str(self.mDX))
        print('mDY = ' + str(self.mDY))
        one = bullet.Bullet(x[0], x[1], self.getDX(), self.getDY(), self.getRotation(), self.getWorldWidth(), self.getWorldHeight())
        print('One mX = ' + str(one.mX))
        print('One mY = ' + str(one.mY))
        print('One mDX = ' + str(one.mDX))
        print('One mDY = ' + str(one.mDY))
        print(self.getPolygon())
        distance = math.sqrt((one.getX() - self.mX) ** 2 + (one.getY() - self.mY) ** 2)
        print('distance = ' + str(distance))
        return one

    def evolve( self, dt ):
        self.move(dt)
        return