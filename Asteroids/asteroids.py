import pygame
import movable
import rotatable
import polygon
import rock
import ship
import random
import star

# this example game draws 3 concentric circles on top of a single color background
# the circles move down every time frame
# the user can control the circles by:
# - clicking the left mouse button to relocate them
# - holding the UP key to move them up
# - pressing the A key to move them to the left of the window
# - holding the A key to gradually move them to the right
class Asteroids:

    def __init__( self, width, height):
        self.mWorldWidth = width
        self.mWorldHeight = height
        self.mShip = ship.Ship(450,450,width,height)
        self.mRocks = []
        self.mStars = []
        self.mBullets = []
        #ye = random.randrange(0,900)
        for i in range(10):
            ye = random.randrange(0,900)
            wut = random.randrange(0,900)
            i = rock.Rock(ye,wut,width,height)
            self.mRocks.append(i)
        print(self.mRocks)

        for i in range(20):
            ye = random.randrange(0,900)
            wut = random.randrange(0,900)
            i = star.Star(ye,wut,width,height)
            self.mStars.append(i)
        print(self.mStars)

        self.mObjects = []
        for ob in self.mStars:
            self.mObjects.append(ob)
        for ob in self.mRocks:
            self.mObjects.append(ob)
        for ob in self.mBullets:
            self.mObjects.append(ob)
        self.mObjects.append(self.mShip)
        return

    def getWorldWidth(self):
        return self.mWorldWidth
    def getWorldHeight(self):
        return self.mWorldHeight
    def getShip(self):
        return self.mShip
    def getRocks(self):
        return self.mRocks
    def getObjects(self):
        return self.mObjects
    def getBullets(self):
        return self.mBullets
    def getStars(self):
        return self.mStars

    def turnShipLeft(self,delta_rotation):
        self.mShip.rotate(-delta_rotation)
        #self.mShip.setPolygon(self.mShip.rotateAndTranslatePointList(self.mShip.getPolygon()))
        return
    def turnShipRight(self,delta_rotation):
        self.mShip.rotate(delta_rotation)
        #self.mShip.setPolygon(self.mShip.rotateAndTranslatePointList(self.mShip.getPolygon()))
        return
    def accelerateShip(self,delta_velocity):
        self.mShip.accelerate(delta_velocity)
        return
    def fire(self):
        if len(self.mBullets) >= 3:
            self.mBullets.pop(0)
            self.mBullets.append(self.mShip.fire())
        if len(self.mBullets) < 3:
            self.mBullets.append(self.mShip.fire())

    def removeInactiveObjects(self):
        for ob in self.mObjects:
            if ob.getActive() == False:
                self.mObjects.remove(ob)
        for ob in self.mBullets:
            if ob.getActive() == False:
                self.mBullets.remove(ob)
        for ob in self.mRocks:
            if ob.getActive() == False:
                self.mRocks.remove(ob)


    def collideShipAndBullets(self):
        #ship is disappearing need to fix
        for bullet in self.mBullets:
            if bullet.getActive() == True:
                if bullet.hits(self.mShip):
                    self.mShip.setActive(False)
                    exit()
                    bullet.setActive(False)

    def collideShipAndRocks(self):
        for rock in self.mRocks:
            if rock.getActive() == True:
                if self.mShip.hits(rock):
                    self.mShip.setActive(False)
                    rock.setActive(False)
                    exit()
                    return True

    def collideRocksAndBullets(self):
        for rock in self.mRocks:
            if rock.getActive() == True:
                for bullet in self.mBullets:
                    if bullet.hits(rock):
                        print(len(self.mRocks))
                        bullet.setActive(False)
                        rock.setActive(False)


    def evolveAllObjects(self,dt):
        #self.collideShipAndBullets()
        self.collideShipAndRocks()
        self.collideRocksAndBullets()
        self.removeInactiveObjects()
        self.collideShipAndBullets()
        for ob in self.mObjects:
            ob.evolve(dt)
        for ob in self.mBullets:
            ob.evolve(dt)
        if len(self.mRocks) == 0:
            self.mShip.setActive(False)
            exit()

    def evolve( self, dt ):
        self.evolveAllObjects(dt)

        #self.removeInactiveObjects()
        #self.collideShipAndBullets()
        ##self.collideShipAndRocks()
        ##self.collideRocksAndBullets()
        #for ye in self.mBullets:
        #    print(ye.getActive())
        #wut = 0
        #wut += dt
        #print(wut)
        #self.mShip.evolve(dt)
        #for i in self.mRocks:
            #print('rotation = ' + str(i.mRotation))
        #    i.evolve(dt)
        #for star in self.mStars:
        #    star.evolve(dt)
        ##for ob in self.mObjects:
            #self.removeInactiveObjects()
        ##    ob.evolve(dt)
        ##for object in self.mBullets:
        ##    object.evolve(dt)
        ##self.removeInactiveObjects()
        return

    # draws the current state of the system
    def draw( self, surface ):

        # rectangle to fill the background
        rect = pygame.Rect( int ( 0 ), int ( 0 ), int ( self.mWorldWidth ), int ( self.mWorldHeight ) )
        pygame.draw.rect( surface, (0,0,0), rect, 0 )

        #self.mShip.draw(surface)

        for object in self.mObjects:
            if object.getActive() == True:
                object.draw(surface)

        for object in self.mBullets:
            object.draw(surface)

        #for star in self.mStars:
        #    star.draw(surface)
        return

    def actOnPressUP(self):
        self.accelerateShip(5)
        return

    def actOnPressDown(self):
        self.accelerateShip(-5)
        return

    def actOnPressLeft(self):
        self.turnShipLeft(5)
        return

    def actOnPressRight(self):
        self.turnShipRight(5)
        print(self.mBullets)
        return
    def actOnPressSpace(self):
        self.fire()
        return






                            #######random shiz
    # move the circles to the left side of the window every time the a button is pressed
    def actOnPressA(self):
        return

    # move the circles right every frame the a button is held down
    # don't let the circles go off the window
    def actOnHoldA(self):
        return

    # raise the circles every frame the UP button is held down
    # don't let the circles go off the window
    def actOnHoldUP(self):

        return

    # relocate the circles based on the mouse click
    # don't let the circles go off the window
    def actOnLeftClick(self, x, y):
        return

