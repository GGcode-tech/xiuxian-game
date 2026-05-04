#!/usr/bin/env python3
"""修仙家族模拟器 - 东方建筑3D模型生成器 (OBJ格式)"""

import math
import os

OUTPUT_DIR = "/home/agentuser/xiuxian_game/picture/buildings_custom"
os.makedirs(OUTPUT_DIR, exist_ok=True)

class OBJ:
    def __init__(self, name):
        self.name = name
        self.v = []
        self.f = []
        
    def vert(self, x, y, z):
        self.v.append((x, y, z))
        return len(self.v)
    
    def face(self, *indices):
        self.f.append(tuple(i for i in indices))
    
    def quad(self, a, b, c, d):
        self.face(a, b, c)
        self.face(a, c, d)
    
    def box(self, x, y, z, w, h, d):
        hw, hh, hd = w/2, h/2, d/2
        b = len(self.v)
        self.v.extend([
            (x-hw,y-hh,z-hd),(x+hw,y-hh,z-hd),(x+hw,y+hh,z-hd),(x-hw,y+hh,z-hd),
            (x-hw,y-hh,z+hd),(x+hw,y-hh,z+hd),(x+hw,y+hh,z+hd),(x-hw,y+hh,z+hd)
        ])
        b += 1
        self.quad(b+4,b+5,b+6,b+7)  # front
        self.quad(b+1,b+0,b+3,b+2)  # back
        self.quad(b+0,b+4,b+7,b+3)  # left
        self.quad(b+5,b+1,b+2,b+6)  # right
        self.quad(b+3,b+7,b+6,b+2)  # top
        self.quad(b+0,b+1,b+5,b+4)  # bottom
    
    def cyl(self, cx, cy, cz, r, h, seg=10):
        b = len(self.v)
        for i in range(seg):
            a = 2*math.pi*i/seg
            self.v.append((cx+r*math.cos(a), cy, cz+r*math.sin(a)))
        for i in range(seg):
            a = 2*math.pi*i/seg
            self.v.append((cx+r*math.cos(a), cy+h, cz+r*math.sin(a)))
        b += 1
        for i in range(seg):
            n = (i+1) % seg
            self.quad(b+i, b+n, b+seg+n, b+seg+i)
        cb = len(self.v) + 1
        self.v.append((cx, cy, cz))
        ct = len(self.v) + 1
        self.v.append((cx, cy+h, cz))
        for i in range(seg):
            n = (i+1) % seg
            self.face(cb, b+n, b+i)
            self.face(ct, b+seg+i, b+seg+n)
    
    def cone(self, cx, cy, cz, r, h, seg=10):
        b = len(self.v)
        for i in range(seg):
            a = 2*math.pi*i/seg
            self.v.append((cx+r*math.cos(a), cy, cz+r*math.sin(a)))
        tip = len(self.v) + 1
        self.v.append((cx, cy+h, cz))
        b += 1
        for i in range(seg):
            n = (i+1) % seg
            self.face(b+i, b+n, tip)
        c = len(self.v) + 1
        self.v.append((cx, cy, cz))
        for i in range(seg):
            n = (i+1) % seg
            self.face(c, b+n, b+i)
    
    def save(self, path):
        os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
        with open(path, 'w') as f:
            f.write(f"# {self.name}\n# Xiuxian Custom Model\n\n")
            for x,y,z in self.v:
                f.write(f"v {x:.4f} {y:.4f} {z:.4f}\n")
            f.write("\n")
            for face in self.f:
                f.write("f " + " ".join(str(i) for i in face) + "\n")
        print(f"  Saved: {path} ({len(self.v)}v, {len(self.f)}f)")

# ============================================================
# 宝塔 (Pagoda) - 5层飞檐宝塔
# ============================================================
def make_pagoda():
    o = OBJ("Pagoda 宝塔")
    y = 0.0
    for tier in range(5):
        s = 1.0 - tier * 0.12
        w = 3.0 * s
        rw = w + 0.8 * (1.0 - tier*0.05)
        wh = 1.2
        # Wall
        o.box(0, y+wh/2, 0, w*0.85, wh, w*0.85)
        # Floor
        o.box(0, y+0.05, 0, w, 0.1, w)
        # Roof
        ry = y + wh
        hrw = rw/2
        cr = 0.15 * s  # corner raise
        mr = cr * 0.3
        peak_h = 0.5 * s
        p = len(o.v)
        o.v.extend([
            (-hrw, ry+0.1+cr, -hrw),  # 0: FL
            (hrw, ry+0.1+cr, -hrw),   # 1: FR
            (hrw, ry+0.1+cr, hrw),    # 2: BR
            (-hrw, ry+0.1+cr, hrw),   # 3: BL
            (0, ry+0.1+mr, -hrw),     # 4: FM
            (hrw, ry+0.1+mr, 0),      # 5: RM
            (0, ry+0.1+mr, hrw),      # 6: BM
            (-hrw, ry+0.1+mr, 0),     # 7: LM
            (0, ry+0.1+peak_h, 0),    # 8: peak
        ])
        b = p + 1
        # Front
        o.face(b+0, b+4, b+8); o.face(b+4, b+1, b+8)
        # Right
        o.face(b+1, b+5, b+8); o.face(b+5, b+2, b+8)
        # Back
        o.face(b+2, b+6, b+8); o.face(b+6, b+3, b+8)
        # Left
        o.face(b+3, b+7, b+8); o.face(b+7, b+0, b+8)
        # Roof flat bottom
        o.box(0, ry, 0, rw, 0.05, rw)
        y = ry + 0.15
    # Spire
    o.cyl(0, y+0.1, 0, 0.06, 1.0, 8)
    o.cone(0, y+1.1, 0, 0.12, 0.25, 8)
    o.cyl(0, y+1.35, 0, 0.08, 0.1, 6)
    o.save(f"{OUTPUT_DIR}/pagoda_5tier.obj")

# ============================================================
# 道观 (Taoist Temple) - 三清殿
# ============================================================
def make_temple():
    o = OBJ("Taoist Temple 道观")
    W, D = 6.0, 4.0
    # Platform
    o.box(0, 0.15, 0, W+1.5, 0.3, D+1.5)
    o.box(0, 0.35, 0, W+1.0, 0.1, D+1.0)
    # Steps
    for i in range(3):
        o.box(0, 0.1*i+0.05, -D/2-0.5-i*0.5, W*0.35, 0.1, 0.5)
    # Walls
    wh = 2.5
    o.box(0, wh/2+0.4, D/2-0.15, W, wh, 0.3)       # back
    o.box(-W/2+0.15, wh/2+0.4, 0, 0.3, wh, D-0.6)   # left
    o.box(W/2-0.15, wh/2+0.4, 0, 0.3, wh, D-0.6)    # right
    o.box(-W/4-0.2, wh/2+0.4, -D/2+0.15, W/2-0.8, wh, 0.3)  # front-L
    o.box(W/4+0.2, wh/2+0.4, -D/2+0.15, W/2-0.8, wh, 0.3)   # front-R
    o.box(0, wh+0.15, -D/2+0.15, 1.6, 0.5, 0.3)     # above door
    # Pillars
    for px in [-W/2+0.4, -W/4, W/4, W/2-0.4]:
        for pz in [-D/2+0.5, D/2-0.5]:
            o.cyl(px, 0.4, pz, 0.12, wh, 8)
    # Roof
    ry = wh + 0.4
    rw = W/2 + 0.9
    rd = D/2 + 0.9
    pk = ry + 1.4
    p = len(o.v)
    o.v.extend([
        (-rw, ry+0.15, -rd), (rw, ry+0.15, -rd),
        (rw, ry+0.15, rd), (-rw, ry+0.15, rd),
        (0, pk, -rd*0.7), (0, pk, rd*0.7),
        (0, ry, -rd), (rw, ry+0.08, 0),
        (0, ry, rd), (-rw, ry+0.08, 0),
    ])
    b = p+1
    # Front slopes
    o.face(b+0,b+6,b+4); o.face(b+6,b+1,b+4)
    # Right slopes
    o.face(b+1,b+7,b+4); o.face(b+7,b+2,b+5)
    # Back slopes
    o.face(b+2,b+8,b+5); o.face(b+8,b+3,b+5)
    # Left slopes
    o.face(b+3,b+9,b+5); o.face(b+9,b+0,b+4)
    # Ceiling
    o.box(0, ry-0.05, 0, W+0.5, 0.1, D+0.5)
    # Plaque
    o.box(0, wh-0.1, -D/2-0.05, 0.8, 0.4, 0.05)
    # Incense burner
    o.cyl(0, 0.4, -D/2-1.5, 0.2, 0.5, 8)
    o.cyl(0, 0.9, -D/2-1.5, 0.25, 0.08, 8)
    o.save(f"{OUTPUT_DIR}/taoist_temple.obj")

# ============================================================
# 山门 (Mountain Gate) - 牌坊
# ============================================================
def make_gate():
    o = OBJ("Mountain Gate 山门")
    W, H = 5.0, 5.0
    o.box(0, 0.15, 0, W+2, 0.3, 2.0)
    o.cyl(-W/2, 0.3, 0, 0.2, H, 10)
    o.cyl(W/2, 0.3, 0, 0.2, H, 10)
    o.cyl(-W/4, 0.3, 0, 0.15, H*0.85, 8)
    o.cyl(W/4, 0.3, 0, 0.15, H*0.85, 8)
    o.box(0, H*0.55, 0, W+0.4, 0.25, 0.3)
    o.box(0, H*0.75, 0, W+0.4, 0.2, 0.25)
    o.box(0, H*0.9, 0, W+0.4, 0.15, 0.2)
    # Roof
    ry = H+0.1
    rw = W/2+0.6
    p = len(o.v)
    o.v.extend([
        (-rw,ry,-1.2),(rw,ry,-1.2),(rw,ry,1.2),(-rw,ry,1.2),
        (0,ry+1.0,-0.6),(0,ry+1.0,0.6)
    ])
    b = p+1
    o.face(b+0,b+1,b+4); o.face(b+2,b+3,b+5)
    o.face(b+3,b+0,b+4); o.face(b+4,b+5,b+3)
    o.face(b+1,b+2,b+5); o.face(b+5,b+4,b+1)
    o.box(0, H+0.05, 0, W+0.8, 0.1, 2.4)
    o.box(0, H*0.75-0.3, 0, 0.8, 0.5, 0.06)
    o.save(f"{OUTPUT_DIR}/mountain_gate.obj")

# ============================================================
# 炼丹阁 (Alchemy Pavilion)
# ============================================================
def make_alchemy():
    o = OBJ("Alchemy Pavilion 炼丹阁")
    W, D = 3.5, 3.5
    o.box(0, 0.15, 0, W+0.5, 0.3, D+0.5)
    wh = 2.0
    o.box(0, wh/2+0.3, D/2, W, wh, 0.2)
    o.box(-W/2, wh/2+0.3, 0, 0.2, wh, D)
    o.box(W/2, wh/2+0.3, 0, 0.2, wh, D)
    # Chimney
    o.cyl(0, wh+0.3, D/2-0.5, 0.15, 1.2, 8)
    # Furnace
    o.cyl(0, 0.6, 0, 0.45, 0.9, 10)
    o.cone(0, 1.5, 0, 0.5, 0.35, 10)
    for i in range(3):
        a = 2*math.pi*i/3
        o.cyl(0.32*math.cos(a), 0.2, 0.32*math.sin(a), 0.06, 0.3, 6)
    o.cyl(0, 0.3, 0, 0.35, 0.1, 8)
    # Roof
    ry = wh+0.35
    o.box(0, ry, 0, W+0.6, 0.1, D+0.6)
    rw = W/2+0.8
    p = len(o.v)
    o.v.extend([
        (-rw,ry+0.1,-D/2-0.3),(rw,ry+0.1,-D/2-0.3),
        (rw,ry+0.1,D/2+0.3),(-rw,ry+0.1,D/2+0.3),
        (0,ry+1.2,-D/2-0.3),(0,ry+1.2,D/2+0.3),
    ])
    b = p+1
    o.face(b+0,b+4,b+1); o.face(b+3,b+5,b+2)
    o.face(b+0,b+3,b+5); o.face(b+5,b+4,b+0)
    o.face(b+1,b+5,b+2); o.face(b+1,b+4,b+5)
    # Shelves
    for i in range(2):
        sy = 0.5+i*0.5
        o.box(-W/2+0.5, sy, D/2-0.3, 0.6, 0.04, 0.25)
        o.box(W/2-0.5, sy, D/2-0.3, 0.6, 0.04, 0.25)
    o.save(f"{OUTPUT_DIR}/alchemy_pavilion.obj")

# ============================================================
# 藏经阁 (Scripture Library) - 两层楼阁
# ============================================================
def make_library():
    o = OBJ("Scripture Library 藏经阁")
    W, D = 5.0, 4.0
    o.box(0, 0.25, 0, W+1.5, 0.5, D+1.5)
    o.box(0, 0.55, 0, W+1.0, 0.1, D+1.0)
    wh = 2.2
    o.box(0, wh/2+0.6, D/2, W, wh, 0.2)
    o.box(-W/2, wh/2+0.6, 0, 0.2, wh, D)
    o.box(W/2, wh/2+0.6, 0, 0.2, wh, D)
    o.box(-W/4-0.25, wh/2+0.6, -D/2, W/2-0.7, wh, 0.2)
    o.box(W/4+0.25, wh/2+0.6, -D/2, W/2-0.7, wh, 0.2)
    o.box(0, wh+0.2, -D/2, 1.4, 0.5, 0.2)
    # Floor 2
    f2y = wh+0.5
    o.box(0, f2y, 0, W+0.2, 0.15, D+0.2)
    w2 = 1.5
    o.box(0, f2y+w2/2, D/2-0.1, W*0.9, w2, 0.2)
    o.box(-W/2+0.1, f2y+w2/2, 0, 0.2, w2, D*0.9)
    o.box(W/2-0.1, f2y+w2/2, 0, 0.2, w2, D*0.9)
    # Railing floor2
    o.box(0, f2y+0.6, -D/2+0.1, W-0.4, 0.5, 0.05)
    # Roof (hipped)
    ry = f2y+w2+0.2
    rw = W/2+1.0
    rd = D/2+1.0
    pk = ry+1.5
    p = len(o.v)
    o.v.extend([
        (-rw,ry+0.15,-rd),(rw,ry+0.15,-rd),
        (rw,ry+0.15,rd),(-rw,ry+0.15,rd),
        (0,pk,-rd*0.6),(0,pk,rd*0.6),
        (0,ry,-rd),(rw,ry+0.08,0),(0,ry,rd),(-rw,ry+0.08,0),
    ])
    b = p+1
    o.face(b+0,b+6,b+4); o.face(b+6,b+1,b+4)
    o.face(b+1,b+7,b+4); o.face(b+7,b+2,b+5)
    o.face(b+2,b+8,b+5); o.face(b+8,b+3,b+5)
    o.face(b+3,b+9,b+5); o.face(b+9,b+0,b+4)
    o.box(0, ry-0.05, 0, W+0.5, 0.1, D+0.5)
    # Bookshelves inside (floor 1)
    for sx in [-W/2+0.5, W/2-0.5]:
        for si in range(3):
            o.box(sx, 0.6+si*0.6, D/2-0.4, 0.5, 0.04, 0.3)
    o.save(f"{OUTPUT_DIR}/scripture_library.obj")

# ============================================================
# 仙人洞府 (Immortal Cave)
# ============================================================
def make_cave():
    o = OBJ("Immortal Cave 仙人洞府")
    # Cave opening (arched)
    seg = 16
    # Left wall of cave entrance
    o.box(-2.0, 1.5, 0, 1.5, 3.0, 2.0)
    # Right wall
    o.box(2.0, 1.5, 0, 1.5, 3.0, 2.0)
    # Top
    o.box(0, 3.2, 0, 2.5, 0.5, 2.0)
    # Natural rock shapes around entrance
    o.cyl(-1.5, 3.5, 0.3, 0.6, 1.0, 7)
    o.cyl(1.5, 3.5, -0.2, 0.5, 0.8, 6)
    o.cyl(-0.8, 3.8, -0.5, 0.4, 0.6, 5)
    # Cave floor
    o.box(0, 0.05, 0.5, 2.0, 0.1, 2.5)
    # Stone platform inside (bed/修炼台)
    o.box(0, 0.35, 1.2, 1.2, 0.5, 1.0)
    # Vine decoration (thin cylinders)
    for vy in [1.0, 2.0, 3.0]:
        o.cyl(-1.8, vy, 0.8, 0.02, 1.0, 4)
        o.cyl(1.8, vy, 0.8, 0.02, 1.0, 4)
    # Moss rocks
    o.cyl(-1.0, 0.15, 1.5, 0.15, 0.3, 5)
    o.cyl(0.7, 0.12, 1.8, 0.12, 0.25, 6)
    o.save(f"{OUTPUT_DIR}/immortal_cave.obj")

# ============================================================
# 灵泉亭 (Spirit Spring Pavilion)
# ============================================================
def make_spring_pavilion():
    o = OBJ("Spirit Spring Pavilion 灵泉亭")
    # Hexagonal pavilion over a spring
    seg = 6
    R = 2.0
    # Stone platform (hexagonal)
    for i in range(seg):
        a1 = 2*math.pi*i/seg
        a2 = 2*math.pi*(i+1)/seg
        p = len(o.v)
        o.v.extend([
            (0, 0.15, 0),
            (R*1.2*math.cos(a1), 0.15, R*1.2*math.sin(a1)),
            (R*1.2*math.cos(a2), 0.15, R*1.2*math.sin(a2)),
            (0, 0, 0),
            (R*1.2*math.cos(a1), 0, R*1.2*math.sin(a1)),
            (R*1.2*math.cos(a2), 0, R*1.2*math.sin(a2)),
        ])
        b = p+1
        o.face(b+0,b+1,b+2)  # top
        o.face(b+5,b+4,b+3)  # bottom
        o.quad(b+1,b+4,b+5,b+2)  # side
    
    # Pillars
    for i in range(seg):
        a = 2*math.pi*i/seg
        o.cyl(R*math.cos(a), 0.3, R*math.sin(a), 0.1, 2.2, 8)
    
    # Spring pool (lower circular area in center)
    o.cyl(0, 0.1, 0, R*0.6, 0.1, 12)
    
    # Roof (hexagonal cone)
    ry = 2.5
    p = len(o.v)
    tip = p + 1
    o.v.append((0, ry+1.5, 0))
    for i in range(seg):
        a = 2*math.pi*i/seg
        o.v.append((R*1.1*math.cos(a), ry, R*1.1*math.sin(a)))
        o.v.append((R*1.1*math.cos(a+math.pi/seg), ry+0.15, R*1.1*math.sin(a+math.pi/seg)))
    b = p+2
    for i in range(seg):
        ei = b + i*2
        ni = b + ((i+1)%seg)*2
        mi = b + i*2 + 1
        o.face(ei, mi, tip)
        o.face(mi, ni, tip)
    
    # Roof underside
    o.cyl(0, ry-0.05, 0, R*0.95, 0.08, seg)
    
    # Finial on top
    o.cyl(0, ry+1.5, 0, 0.05, 0.3, 6)
    o.cone(0, ry+1.8, 0, 0.08, 0.15, 6)
    
    o.save(f"{OUTPUT_DIR}/spirit_spring_pavilion.obj")

# ============================================================
# Run all generators
# ============================================================
if __name__ == "__main__":
    print("=== 修仙东方建筑3D模型生成器 ===\n")
    make_pagoda()
    make_temple()
    make_gate()
    make_alchemy()
    make_library()
    make_cave()
    make_spring_pavilion()
    print(f"\n✅ 所有建筑模型已保存到 {OUTPUT_DIR}/")
