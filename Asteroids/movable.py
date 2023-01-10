import math
class Movable:

    def __init__(self, x, y, dx, dy, w, h):
        self.mX = x
        self.mY = y
        self.mDX = dx
        self.mDY = dy
        self.mWorldWidth = w
        self.mWorldHeight = h
        self.mActive = True

    def getX(self):
        return self.mX
    def getY(self):
        return self.mY
    def getDX(self):
        return self.mDX
    def getDY(self):
        return self.mDY
    def getWorldWidth(self):
        return self.mWorldWidth
    def getWorldHeight(self):
        return self.mWorldHeight
    def getActive(self):
        return self.mActive
    def getRadius(self):
        return

    def setActive(self,active):
        self.mActive = active

    def hits(self,other):
        ye = math.sqrt(((self.getX() - other.getX()) ** 2) + ((self.getY() - other.getY()) ** 2))
        wut = self.getRadius() + other.getRadius()
        if wut >= ye:
            return True
        else:
            return False



    def move(self,dt):
        new_x = self.mX + (self.mDX * dt)
        new_y = self.mY + (self.mDY * dt)

        if new_x < 0:
            new_x = self.mWorldWidth - dt
        if new_x >= self.mWorldWidth:
            new_x -= self.mWorldWidth

        if new_y <= 0:
            new_y += self.mWorldHeight
        if new_y >= self.mWorldHeight:
            new_y -= self.mWorldHeight

        self.mX = new_x
        self.mY = new_y

#        print("dy = " + str(self.mDY))
#        print("dx = " + str(self.mDX))
#        print("x = " + str(self.mX))
#        print("y = " + str(self.mY))
#        print("dt = " + str(dt))
#        print("new_x = " + str(new_x))
#        print("new_y = " + str(new_y))
        return

    def accelerate(self,delta_velocity):
        return

    def evolve( self, dt ):
#        if self.game_over:
#            return

#        self.frog.move()
#        if self.frog.outOfBounds(self.mWidth,self.mHeight):
#            self.game_over = True

#        for item_tuple in self.lanes:
#            item, color = item_tuple
#            if isinstance(item, froggerlib.Movable):
#                item.move()
#                if item.atDesiredLocation():
#                    if item.getDesiredX() > 0:
#                        #move to the left side of the screen
#                        x = -item.getWidth()
#                    else:
#                        #move it to the right
#                        x = self.mWidth
#                    item.setX(x)
#            item.supports(self.frog)

#            if item.hits(self.frog):
#                self.game_over = True
        return


    def draw(self, surface):
#        background = pygame.Rect(0, 0, self.mWidth, self.mHeight)
#        pygame.draw.rect(surface, self.mbackground, background, 0)

#        for item_tuple in self.lanes:
#            item, color = item_tuple
#            rect = pygame.Rect(item.getX(), item.getY(), item.getWidth(), item.getHeight())
#            pygame.draw.rect(surface, color, rect, 0)

#        froggy = pygame.Rect(self.frog.getX(), self.frog.getY(), self.frog.getWidth(), self.frog.getHeight())
#        # print(self.frog.mX,self.frog.getY(),self.frog.getWidth(),self.frog.getHeight())
#        pygame.draw.rect(surface, self.frog_color, froggy, 0)

        return



