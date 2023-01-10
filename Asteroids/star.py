import circle
import random

class Star(circle.Circle):
    def __init__(self, x, y, w, h):
        dx = 0
        dy = 0
        r = 0
        radius = 2
        circle.Circle.__init__(self, x, y, dx, dy, r, radius, w, h)
        self.mBrightness = 0

    def getBrightness(self):
        return self.mBrightness

    def setBrightness(self,brightness):
        if brightness < 0 or brightness > 255:
            return
        else:
            self.mColor = (brightness,brightness,brightness)
            self.mBrightness = brightness

    def evolve( self, dt ):
        yuh = random.randrange(1,100)
        self.setBrightness(yuh)
        return