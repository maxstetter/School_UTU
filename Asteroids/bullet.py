import circle

class Bullet(circle.Circle):
    def __init__(self, x, y, dx, dy, r, w, h):
        radius = 3

        circle.Circle.__init__(self, x, y, dx, dy, r, radius, w, h)
        self.accelerate(100.0)
        self.mAge = 0
        #print('x = ' + str(self.mX))
        #print('y = ' + str(self.mY))
        self.mX += 0.1 * self.mDX
        self.mY += 0.1 * self.mDY

    def getAge(self):
        return self.mAge

    def setAge(self,age):
        self.mAge = age

    def evolve( self, dt ):
        #print('before' + str(self.getAge()))
        #print('dt = ' + str(dt))
        self.setAge(self.mAge + dt)
        self.move(dt)

        if self.mAge < 6.0:
            self.setActive(True)
        if self.mAge > 6.0:
            self.setActive(False)
        #print('after' + str(self.getAge()))
        return


