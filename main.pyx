
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
            <div style={{
                'position': 'absolute',
                'top': f'{self.y - self.panel.panelOffsetY}px',
                'left': f'{self.x - self.panel.panelOffsetX}px',
                }} onTouchStart={onTouchStart}>
                {self.target}
            </div>
        )

class Variable:
    def __init__(self, value, label=''):
        self.value = value
        self.label = label
    
    def update(self, value):
        pass

    def __render__(self, user):
        return (
            <div style={{
                'border': '1px solid #ccc',
                'borderRadius': '4px',
                'padding': '4px',
                    'backgroundColor': '#fff',
                'fontWeight': 'normal',
            }}>
                {self.label} = <span style={{
                    'fontWeight': 'bold',
                }}>{self.value}</span>
            </div>
        )

class Operator(Variable):
    def __init__(self, label, ftn):
        self.label = label
        self.ftn = ftn
        self.value = None
    
    def update(self, value):
        if value is not None:
            self.value = round(self.ftn(value), 2)
        else:
            self.value = None
    
    def __render__(self, user):
        if self.value is None:
            return (
                <div style={{
                    'border': '1px solid #ccc',
                    'borderRadius': '4px',
                    'padding': '4px',
                    'color': '#aaa',
                    'backgroundColor': '#fff',
                    'fontWeight': 'normal',
                }}>
                    {self.label}
                </div>
            )
        else:
            return (
                <div style={{
                    'border': '1px solid #ccc',
                    'borderRadius': '4px',
                    'padding': '4px',
                    'backgroundColor': '#fff',
                    'fontWeight': 'normal',
                }}>
                    {self.label} = <span style={{
                        'fontWeight': 'bold',
                    }}>{self.value}</span>
                </div>
            )


class DevelopPanel:
    def __init__(self, user):
        self.user = user
        self.height = 320
        self.floaters = []
        self.panelOffsetX = 0
        self.panelOffsetY = 0
        self.isDragging = False
        self.dragOffsetX = 0
        self.dragOffsetY = 0

        self.directionVariable = Variable(0, 'Direction')
        self.distanceVariable = Variable(0, 'Speed')

        def moveCharacter(x, y, delta=False):
            if delta:
                self.user['character'].x += x
                self.user['character'].y -= y
            else:
                if x is not None:
                    self.user['character'].x = x
                if y is not None:
                    self.user['character'].y = y
            self.user.forceUpdate(self.user['character'])
            if x is None: return y
            if y is None: return x
            return x + y

        self.addFloater(self.directionVariable, 10, 10)
        self.addFloater(self.directionVariable, 10, 40)

        self.addFloater(Operator('→ add to character X', lambda x: moveCharacter(x, 0, True)), 150, 10)
        self.addFloater(Operator('→ add to character Y', lambda x: moveCharacter(0, x, True)), 150, 40)
        # self.addFloater(Operator('→ set character X', lambda x: moveCharacter(x, None)), 150, 70)
        # self.addFloater(Operator('→ set character Y', lambda x: moveCharacter(None, x)), 150, 100)

        self.addFloater(Operator(' * π ÷ 180', lambda x: x * math.pi / 180), 10, 130)
        self.addFloater(Operator(' * π ÷ 180', lambda x: x * math.pi / 180), 10, 160)
        # self.addFloater(Operator(' * 0.1', lambda x: x * 0.1), 10, 190)
        # self.addFloater(Operator(' * 5', lambda x: x * 5), 10, 220)
        # self.addFloater(Operator(' * 10', lambda x: x * 10), 10, 250)
        # self.addFloater(Operator(' * 100', lambda x: x * 0.001), 10, 280)
        self.addFloater(Operator(' * speed', lambda x: x * self.user['distance']/10), 100, 130)
        self.addFloater(Operator(' * speed', lambda x: x * self.user['distance']/10), 100, 160)

        self.addFloater(Operator('sin(𝑥)', lambda x: math.sin(x)), 100, 190)
        self.addFloater(Operator('cos(𝑥)', lambda x: math.cos(x)), 100, 220)


    def onTick(self, deltaTime):
        try:
            for target in self.floaters:
                target.target.update(None)
                for floater in self.floaters:
                    if floater.target == target: continue
                    if target.y > floater.y + 20 and target.y < floater.y + 40:
                        if target.x > floater.x - 10 and target.x < floater.x + 10:
                            target.target.update(floater.target.value)
        except Exception as e:
            print(e)
    
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
            <div style={{
                'width': '100vw',
                'height': f'{self.height}px',
                'borderBottom': '1px solid #ccc',
                'position': 'fixed',
                'top': '0px',
                'left': '0px',
                'backgroundColor': '#fff',
                'overflow': 'hidden',
            }} onTouchMove={self.onTouchMove} onTouchEnd={self.onTouchEnd} onTouchStart={self.onTouchStart}>
                {self.floaters}
            </div>
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
            <div style={{
                'width': '130px',
                'height': '130px',
                'borderRadius': '50%',
                'backgroundColor': '#bbb',
                'position': 'absolute',
                'top': f"calc({self.y})",
                'left': f"calc({self.x})",
                'transform': 'translate(-50%, -50%)',
            }}>
                <div style={{
                    'width': '45px',
                    'height': '45px',
                    'borderRadius': '50%',
                    'backgroundColor': '#999',
                    'position': 'absolute',
                    'top': f"calc({self.stickY} + 50%)",
                    'left': f"calc({self.stickX} + 50%)",
                    'transform': 'translate(-50%, -50%)',
                    'userSelect': 'none',
                }} onTouchStart={onTouchStart} onTouchEnd={self.onTouchEnd}></div>
            </div>
        )

class Character:
    def __init__(self, user):
        self.user = user
        self.x = 32
        self.y = 420
        self.speed = 0
        self.color = '#c99'
    
    def __render__(self, user):
        return (
            <div style={{
                'width': '32px',
                'height': '32px',
                'backgroundColor': self.color,
                'position': 'absolute',
                'top': f"{self.y}px",
                'left': f"{self.x}px",
                'borderRadius': '40%',
                'transform': f'rotate({self.user["direction"]}deg)',
            }}>
                <div style={{
                    'width': '4px',
                    'height': '4px',
                    'backgroundColor': '#000',
                    'position': 'absolute',
                    'right': '6px',
                    'top': '10px',
                    'borderRadius': '50%',
                }}></div>
                <div style={{
                    'width': '4px',
                    'height': '4px',
                    'backgroundColor': '#000',
                    'position': 'absolute',
                    'right': '6px',
                    'top': '18px',
                    'borderRadius': '50%',
                }}></div>
            </div>
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
            <div style={{
                'width': '100vw',
                'height': '92vh',
                'backgroundColor': '#f9f9fb',
                'position': 'relative',
                'overflow': 'hidden',
            }} onTouchMove={self.onTouchMove} onTouchEnd={self.onTouchEnd}>
                GamePanel
                {user['joystick']}
                {[user['character'] for user in user.app.users.values()]}
            </div>
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
            await tornado.gen.sleep(0.05)
            currentTime = time.time()
            deltaTime = currentTime - lastTime
            lastTime = currentTime
            await self.onTick(deltaTime)
    
    async def onTick(self, deltaTime):
        for user in self.users.values():
            # if user['distance'] > 0:
            #     user['character'].x += math.cos(user['direction'] * math.pi / 180) * user['distance'] * deltaTime * 2
            #     user['character'].y += math.sin(user['direction'] * math.pi / 180) * user['distance'] * deltaTime * 2
            #     user.forceUpdate(user['character'])
            user['developPanel'].onTick(deltaTime)
    
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
            return <button onClick={self.startTick}>Start</button>
        return (
            <div>
                {self.gamePanel}
                {user['developPanel']}
            </div>
        )

app = MainApp()
app.run('0.0.0.0', 7002)

