import rotatable
import pygame

class Circle(rotatable.Rotatable):
    def __init__(self, x, y, dx, dy, r, radius, w, h):
        rotatable.Rotatable.__init__(self, x, y, dx, dy, r, w, h)
        self.mColor = (255, 255, 255)
        self.mRadius = radius

    def getRadius(self):
        return self.mRadius
    def getColor(self):
        return self.mColor

    def setRadius(self, radius):
        if radius < 1:
            return
        else:
            self.mRadius = radius
            print(self.mRadius)

    def setColor(self, color):
        self.mColor = color

    def draw(self, surface):
        pygame.draw.circle(surface,self.mColor,(int(self.mX), int(self.mY)),self.mRadius,0)
