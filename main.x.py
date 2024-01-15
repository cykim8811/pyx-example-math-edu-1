import pyx

import pyx

class Floater:
    def __init__(self, panel, target, x, y):
        self.panel = panel
        self.target = target
        self.x = x
        self.y = y
        self.isDragging = False
        self.dragOffsetX = 0
        self.dragOffsetY = 0
        self.panelOffsetX = 0
        self.panelOffsetY = 0
    
    async def onTouchMove(self, e):
        if self.isDragging:
            mx = await e.touches[0].clientX
            my = await e.touches[0].clientY
            if self.dragOffsetX is None:
                self.dragOffsetX = mx - self.x
                self.dragOffsetY = my - self.y
            self.x = mx - self.dragOffsetX
            self.y = my - self.dragOffsetY
    
    async def onTouchEnd(self, e):
        self.isDragging = False
    
    def __render__(self, user):
        async def onTouchStart(e):
            self.isDragging = True
            self.panel.onFloaterTouchStart(self, e)
            self.dragOffsetX = None
            self.dragOffsetY = None
        onTouchStart.stopPropagation = True
        
        return (
            pyx.createElement("div", {"style": {
                'position': 'absolute',
                'top': f'{self.y - self.panel.panelOffsetY}px',
                'left': f'{self.x - self.panel.panelOffsetX}px',
                }, "onTouchStart": onTouchStart},  self.target)
        )

class Variable:
    def __init__(self, value, label=''):
        self.value = value
        self.label = label

    def __render__(self, user):
        return (
            pyx.createElement("div", {},  self.label + (':' if self.label != '' else ''),  self.value)
        )

class Toolbar:
    def __init__(self):
        pass
    
    def __render__(self, user):
        return (
            pyx.createElement("div", {},  "Toolbar\n            ")
        )

class DevelopPanel:
    def __init__(self, user):
        self.user = user
        self.height = 160
        self.floaters = []
        self.panelOffsetX = 0
        self.panelOffsetY = 0
        self.isDragging = False
        self.dragOffsetX = 0
        self.dragOffsetY = 0

        self.directionVariable = Variable(0, 'Direction')
        self.distanceVariable = Variable(0, 'Speed')

        self.addFloater(self.directionVariable, 50, 50)
        self.addFloater(self.distanceVariable, 50, 80)

        self.toolbar = Toolbar()
    
    def addFloater(self, target, x, y):
        self.floaters.append(Floater(self, target, x, y))
        self.floaters = self.floaters
        return self.floaters[-1]
    
    def onFloaterTouchStart(self, floater, e):
        self.floaters.remove(floater)
        self.floaters.append(floater)
        self.floaters = self.floaters
        
    async def onTouchMove(self, e):
        if self.isDragging:
            mx = await e.touches[0].clientX
            my = await e.touches[0].clientY
            if self.dragOffsetX is None:
                self.dragOffsetX = mx + self.panelOffsetX
                self.dragOffsetY = my + self.panelOffsetY
            self.panelOffsetX = self.dragOffsetX - mx
            self.panelOffsetY = self.dragOffsetY - my
            for floater in self.floaters:
                floater.panelOffsetX = self.panelOffsetX
                floater.panelOffsetY = self.panelOffsetY
                self.user.forceUpdate(floater)
        else:
            for floater in self.floaters:
                await floater.onTouchMove(e)
        
    async def onTouchEnd(self, e):
        self.isDragging = False
        for floater in self.floaters:
            await floater.onTouchEnd(e)
    
    async def onTouchStart(self, e):
        self.isDragging = True
        self.dragOffsetX = None
        self.dragOffsetY = None
    
    def __render__(self, user):
        self.directionVariable.value = round(-user['direction'], 2)
        self.distanceVariable.value = round(user['distance'])
        return (
            pyx.createElement("div", {"style": {
                'width': '100vw',
                'height': f'{self.height}px',
                'borderBottom': '1px solid #ccc',
                'position': 'fixed',
                'top': '0px',
                'left': '0px',
                'backgroundColor': '#fff',
                'overflow': 'hidden',
            }, "onTouchMove": self.onTouchMove, "onTouchEnd": self.onTouchEnd, "onTouchStart": self.onTouchStart},  self.floaters,  self.toolbar)
        )

import math

class Joystick:
    def __init__(self, user):
        self.user = user
        self.x = "50vw"
        self.y = "80vh"
        self.stickX = "0px"
        self.stickY = "0px"
        self.isDragging = False
        self.originX = 0
        self.originY = 0
    
    async def onTouchMove(self, e):
        mx = await e.touches[0].clientX
        my = await e.touches[0].clientY
        if self.isDragging:
            if self.originX is None:
                self.originX = mx
                self.originY = my
            dx = (mx - self.originX)
            dy = (my - self.originY)
            dr = (dx ** 2 + dy ** 2) ** 0.5
            if dr > 55:
                dx = dx / dr * 55
                dy = dy / dr * 55
                mx = self.originX + dx
                my = self.originY + dy
            self.stickX = f"{round(mx)}px - {self.x}"
            self.stickY = f"{round(my)}px - {self.y}"

            self.user['distance'] = (dx ** 2 + dy ** 2) ** 0.5
            self.user['direction'] = math.atan2(dy, dx) * 180 / math.pi

    
    async def onTouchEnd(self, e):
        self.isDragging = False
        self.stickX = "0px"
        self.stickY = "0px"
        self.user['distance'] = 0
        self.user.forceUpdate(self)
        
    def __render__(self, user):
        async def onTouchStart(e):
            self.isDragging = True
            self.originY = None
            self.originX = None
        
        return (
            pyx.createElement("div", {"style": {
                    'width': '45px',
                    'height': '45px',
                    'borderRadius': '50%',
                    'backgroundColor': '#999',
                    'position': 'absolute',
                    'top': f"calc({self.stickY} + 50%)",
                    'left': f"calc({self.stickX} + 50%)",
                    'transform': 'translate(-50%, -50%)',
                    'userSelect': 'none',
                }, "onTouchStart": onTouchStart, "onTouchEnd": self.onTouchEnd, "style": {
                'width': '130px',
                'height': '130px',
                'borderRadius': '50%',
                'backgroundColor': '#bbb',
                'position': 'absolute',
                'top': f"calc({self.y})",
                'left': f"calc({self.x})",
                'transform': 'translate(-50%, -50%)',
            }}, 
                pyx.createElement("div", {"style": {
                    'width': '45px',
                    'height': '45px',
                    'borderRadius': '50%',
                    'backgroundColor': '#999',
                    'position': 'absolute',
                    'top': f"calc({self.stickY} + 50%)",
                    'left': f"calc({self.stickX} + 50%)",
                    'transform': 'translate(-50%, -50%)',
                    'userSelect': 'none',
                }, "onTouchStart": onTouchStart, "onTouchEnd": self.onTouchEnd}, ))
        )

class Character:
    def __init__(self, user):
        self.user = user
        self.x = 32
        self.y = 240
        self.speed = 0
        self.color = '#c99'
    
    def __render__(self, user):
        return (
            pyx.createElement("div", {"style": {
                'width': '32px',
                'height': '32px',
                'backgroundColor': self.color,
                'position': 'absolute',
                'top': f"{self.y}px",
                'left': f"{self.x}px",
                'borderRadius': '40%',
                'transform': f'rotate({self.user["direction"]}deg)',
            }}, )
        )

class GamePanel:
    async def onTouchMove(self, e):
        await e.user['joystick'].onTouchMove(e)
    
    async def onTouchEnd(self, e):
        await e.user['joystick'].onTouchEnd(e)
    
    def __render__(self, user):
        if 'joystick' not in user.data:
            user['joystick'] = Joystick(user)
        return (
            pyx.createElement("div", {"style": {
                'width': '100vw',
                'height': '92vh',
                'backgroundColor': '#f9f9fb',
                'position': 'relative',
                'overflow': 'hidden',
            }, "onTouchMove": self.onTouchMove, "onTouchEnd": self.onTouchEnd},  "GamePanel\n                ",  user['joystick'],  [user['character'] for user in user.app.users.values()])
        )

import tornado.gen
import time

class MainApp(pyx.App):
    def __init__(self):
        super().__init__()
        self.gamePanel = GamePanel()
        self.tickRunning = False
        
    async def startTick(self, e):
        self.tickRunning = True
        lastTime = time.time()
        while True:
            await tornado.gen.sleep(0.01)
            currentTime = time.time()
            deltaTime = currentTime - lastTime
            lastTime = currentTime
            await self.onTick(deltaTime)
    
    async def onTick(self, deltaTime):
        for user in self.users.values():
            if user['distance'] > 0:
                user['character'].x += math.cos(user['direction'] * math.pi / 180) * user['distance'] * deltaTime * 2
                user['character'].y += math.sin(user['direction'] * math.pi / 180) * user['distance'] * deltaTime * 2
                user.forceUpdate(user['character'])
    
    def onConnect(self, user):
        user['developPanel'] = DevelopPanel(user)
        user['character'] = Character(user)

        user['distance'] = 0
        user['direction'] = 0
    
    def onDisconnect(self, user):
        for user in self.users.values():
            user.forceUpdate(self.gamePanel)
    
    async def onTouchMove(self):
        pass

    def __render__(self, user):
        if not self.tickRunning:
            return pyx.createElement("button", {"onClick": self.startTick}, "Start")
        return (
            pyx.createElement("div", {},  self.gamePanel,  user['developPanel'])
        )

app = MainApp()
app.run('0.0.0.0', 7002)

