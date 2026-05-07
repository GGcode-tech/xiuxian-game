#!/usr/bin/env python3
"""测试的小修仙世界 - 角色与灵兽3D模型生成器 (OBJ格式)"""

import math
import os

OUTPUT_DIR = "/home/agentuser/xiuxian_game/picture/characters_custom"
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
        self.quad(b+4,b+5,b+6,b+7)
        self.quad(b+1,b+0,b+3,b+2)
        self.quad(b+0,b+4,b+7,b+3)
        self.quad(b+5,b+1,b+2,b+6)
        self.quad(b+3,b+7,b+6,b+2)
        self.quad(b+0,b+1,b+5,b+4)
    
    def cyl(self, cx, cy, cz, r, h, seg=10, top=True, bottom=True):
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
        if bottom:
            cb = len(self.v) + 1
            self.v.append((cx, cy, cz))
            for i in range(seg):
                n = (i+1) % seg
                self.face(cb, b+n, b+i)
        if top:
            ct = len(self.v) + 1
            self.v.append((cx, cy+h, cz))
            for i in range(seg):
                n = (i+1) % seg
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
    
    def sphere(self, cx, cy, cz, r, seg=8, rings=6):
        """Simple UV sphere"""
        # Generate vertices
        for ring in range(rings + 1):
            phi = math.pi * ring / rings
            for i in range(seg):
                theta = 2 * math.pi * i / seg
                x = cx + r * math.sin(phi) * math.cos(theta)
                y = cy + r * math.cos(phi)
                z = cz + r * math.sin(phi) * math.sin(theta)
                self.v.append((x, y, z))
        
        # Generate faces
        for ring in range(rings):
            for i in range(seg):
                next_i = (i + 1) % seg
                current = ring * seg + i + 1
                next_row = (ring + 1) * seg + i + 1
                next_col = ring * seg + next_i + 1
                next_both = (ring + 1) * seg + next_i + 1
                
                if ring == 0:  # Top cap
                    self.face(current, next_both, next_row)
                elif ring == rings - 1:  # Bottom cap
                    self.face(current, next_col, next_both)
                else:
                    self.face(current, next_col, next_both)
                    self.face(current, next_both, next_row)
    
    def save(self, path):
        os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
        with open(path, 'w') as f:
            f.write(f"# {self.name}\n# Xiuxian Character Model\n\n")
            for x,y,z in self.v:
                f.write(f"v {x:.4f} {y:.4f} {z:.4f}\n")
            f.write("\n")
            for face in self.f:
                f.write("f " + " ".join(str(i) for i in face) + "\n")
        print(f"  Saved: {path} ({len(self.v)}v, {len(self.f)}f)")


# ============================================================
# 修士 (Cultivator) - 基础修仙者
# ============================================================
def make_cultivator_male():
    o = OBJ("Cultivator Male 男修士")
    # Head
    o.sphere(0, 1.6, 0, 0.25, 8, 6)
    # Hair (topknot style)
    o.cyl(0, 1.85, -0.05, 0.12, 0.3, 8)
    o.sphere(0, 2.15, -0.05, 0.08, 6, 4)
    # Body (robed torso)
    o.cyl(0, 0.95, 0, 0.28, 0.8, 8)
    # Robe bottom (wider)
    o.cyl(0, 0.35, 0, 0.32, 0.7, 8)
    # Arms
    o.cyl(-0.35, 1.0, 0, 0.08, 0.6, 6)
    o.cyl(0.35, 1.0, 0, 0.08, 0.6, 6)
    o.cyl(-0.35, 0.65, 0, 0.07, 0.35, 6)
    o.cyl(0.35, 0.65, 0, 0.07, 0.35, 6)
    # Hands
    o.sphere(-0.35, 0.45, 0, 0.06, 5, 4)
    o.sphere(0.35, 0.45, 0, 0.06, 5, 4)
    # Feet
    o.box(-0.12, 0.05, 0.03, 0.12, 0.1, 0.22)
    o.box(0.12, 0.05, 0.03, 0.12, 0.1, 0.22)
    # Sword on back
    o.box(0.15, 1.1, -0.2, 0.06, 1.0, 0.02)
    o.box(0.15, 1.65, -0.2, 0.07, 0.08, 0.03)
    o.save(f"{OUTPUT_DIR}/cultivator_male.obj")

def make_cultivator_female():
    o = OBJ("Cultivator Female 女修士")
    # Head
    o.sphere(0, 1.5, 0, 0.22, 8, 6)
    # Long hair
    o.cyl(-0.15, 1.55, -0.08, 0.1, 0.4, 6, top=False)
    o.cyl(0.15, 1.55, -0.08, 0.1, 0.4, 6, top=False)
    o.cyl(0, 1.45, -0.15, 0.18, 0.6, 8, top=False)
    # Body (elegant robe)
    o.cyl(0, 0.95, 0, 0.22, 0.6, 8)
    # Robe flare
    o.cyl(0, 0.4, 0, 0.28, 0.9, 8)
    # Sleeves (flowing)
    o.cyl(-0.32, 0.95, 0.05, 0.1, 0.55, 6)
    o.cyl(0.32, 0.95, 0.05, 0.1, 0.55, 6)
    # Hands
    o.sphere(-0.38, 0.55, 0.08, 0.05, 4, 3)
    o.sphere(0.38, 0.55, 0.08, 0.05, 4, 3)
    # Feet
    o.box(0, 0.04, 0.02, 0.18, 0.08, 0.18)
    # Hair ornament
    o.sphere(0.12, 1.72, -0.02, 0.03, 4, 3)
    o.save(f"{OUTPUT_DIR}/cultivator_female.obj")

# ============================================================
# 剑修 (Sword Cultivator) - 剑修
# ============================================================
def make_sword_cultivator():
    o = OBJ("Sword Cultivator 剑修")
    # Head
    o.sphere(0, 1.55, 0, 0.23, 8, 6)
    # Hair (topknot)
    o.cyl(0, 1.78, -0.05, 0.1, 0.25, 7)
    o.cone(0, 2.03, -0.05, 0.08, 0.15, 6)
    # Body (tight robe)
    o.cyl(0, 0.95, 0, 0.25, 0.7, 8)
    o.cyl(0, 0.4, 0, 0.26, 0.8, 8)
    # Arms holding sword
    o.cyl(-0.35, 1.0, 0.1, 0.07, 0.5, 6)
    o.cyl(0.35, 1.0, 0.1, 0.07, 0.5, 6)
    # Hands
    o.sphere(-0.35, 0.75, 0.12, 0.05, 5, 4)
    o.sphere(0.35, 0.75, 0.12, 0.05, 5, 4)
    # Sword (held in front)
    o.box(0, 0.85, 0.35, 0.04, 1.2, 0.01)
    o.box(0, 0.38, 0.35, 0.06, 0.12, 0.02)
    o.cyl(0, 0.3, 0.35, 0.03, 0.08, 6)
    # Flying sword aura (behind)
    o.box(0, 1.5, -0.4, 0.5, 0.03, 0.02)
    o.box(0, 1.2, -0.4, 0.35, 0.03, 0.02)
    # Belt
    o.cyl(0, 0.95, 0, 0.28, 0.08, 8, top=False, bottom=False)
    # Feet
    o.box(-0.1, 0.04, 0.02, 0.12, 0.08, 0.2)
    o.box(0.1, 0.04, 0.02, 0.12, 0.08, 0.2)
    o.save(f"{OUTPUT_DIR}/sword_cultivator.obj")

# ============================================================
# 丹修 (Alchemy Cultivator) - 炼丹师
# ============================================================
def make_alchemist():
    o = OBJ("Alchemist 丹修")
    # Head
    o.sphere(0, 1.5, 0, 0.24, 8, 6)
    # Headband
    o.cyl(0, 1.55, 0, 0.26, 0.05, 8, top=False, bottom=False)
    # Hair (messy from alchemy fumes)
    o.sphere(0, 1.72, 0, 0.12, 6, 4)
    o.sphere(0.08, 1.68, -0.08, 0.05, 4, 3)
    # Body
    o.cyl(0, 0.9, 0, 0.27, 0.7, 8)
    o.cyl(0, 0.35, 0, 0.3, 0.75, 8)
    # Arms stretched forward (working on cauldron)
    o.cyl(-0.35, 0.95, 0.15, 0.07, 0.45, 6)
    o.cyl(0.35, 0.95, 0.15, 0.07, 0.45, 6)
    # Hands
    o.sphere(-0.35, 0.72, 0.2, 0.05, 5, 4)
    o.sphere(0.35, 0.72, 0.2, 0.05, 5, 4)
    # Small cauldron held
    o.cyl(0, 0.55, 0.35, 0.15, 0.25, 8)
    o.cyl(0, 0.8, 0.35, 0.18, 0.08, 8, bottom=False)
    # Herb pouch on belt
    o.box(-0.25, 0.85, 0.1, 0.12, 0.18, 0.08)
    # Feet
    o.box(-0.1, 0.04, 0, 0.12, 0.08, 0.18)
    o.box(0.1, 0.04, 0, 0.12, 0.08, 0.18)
    o.save(f"{OUTPUT_DIR}/alchemist.obj")

# ============================================================
# 体修 (Body Cultivator) - 炼体者
# ============================================================
def make_body_cultivator():
    o = OBJ("Body Cultivator 体修")
    # Head
    o.sphere(0, 1.4, 0, 0.27, 8, 6)
    # Bald/buzzed hair
    o.sphere(0, 1.58, 0, 0.15, 6, 4)
    # Thick neck
    o.cyl(0, 1.15, 0, 0.15, 0.12, 8)
    # Muscular torso (wider)
    o.cyl(0, 0.8, 0, 0.32, 0.6, 8)
    # Belt/wrap
    o.cyl(0, 0.58, 0, 0.3, 0.1, 8, top=False, bottom=False)
    # Lower body
    o.cyl(0, 0.3, 0, 0.25, 0.55, 8)
    # Thick arms (muscular)
    o.cyl(-0.4, 0.85, 0, 0.1, 0.5, 6)
    o.cyl(0.4, 0.85, 0, 0.1, 0.5, 6)
    o.cyl(-0.4, 0.55, 0, 0.09, 0.35, 6)
    o.cyl(0.4, 0.55, 0, 0.09, 0.35, 6)
    # Fists
    o.sphere(-0.4, 0.35, 0, 0.08, 5, 4)
    o.sphere(0.4, 0.35, 0, 0.08, 5, 4)
    # Feet (barefoot, wider)
    o.box(-0.12, 0.05, 0.02, 0.14, 0.1, 0.24)
    o.box(0.12, 0.05, 0.02, 0.14, 0.1, 0.24)
    o.save(f"{OUTPUT_DIR}/body_cultivator.obj")

# ============================================================
# 长老 (Elder) - 宗门长老
# ============================================================
def make_elder():
    o = OBJ("Elder 长老")
    # Head
    o.sphere(0, 1.65, 0, 0.24, 8, 6)
    # Long white beard
    o.cyl(0, 1.45, 0.12, 0.08, 0.5, 5, top=False)
    o.cone(0, 1.35, 0.18, 0.1, 0.35, 5)
    # Long white hair
    o.cyl(0, 1.7, -0.08, 0.15, 0.45, 8, top=False)
    o.cyl(-0.12, 1.65, -0.1, 0.08, 0.5, 6, top=False)
    o.cyl(0.12, 1.65, -0.1, 0.08, 0.5, 6, top=False)
    # Body (elaborate robe)
    o.cyl(0, 1.0, 0, 0.28, 0.75, 8)
    o.cyl(0, 0.4, 0, 0.35, 0.95, 8)
    # Long sleeves
    o.cyl(-0.38, 1.0, 0.05, 0.12, 0.7, 6)
    o.cyl(0.38, 1.0, 0.05, 0.12, 0.7, 6)
    # Hands (subtle)
    o.sphere(-0.32, 0.5, 0.08, 0.04, 4, 3)
    o.sphere(0.32, 0.5, 0.08, 0.04, 4, 3)
    # Staff
    o.cyl(-0.35, 0.95, 0.2, 0.03, 1.5, 6)
    o.sphere(-0.35, 1.7, 0.2, 0.06, 6, 4)
    # Feet hidden by robe
    o.save(f"{OUTPUT_DIR}/elder.obj")

# ============================================================
# 灵兽 (Spirit Beasts)
# ============================================================
def make_qilin():
    """麒麟 - auspicious beast"""
    o = OBJ("Qilin 麒麟")
    # Body
    o.sphere(0, 0.5, 0, 0.45, 8, 6)
    o.cyl(-0.3, 0.45, 0, 0.35, 0.6, 8)
    # Neck
    o.cyl(0.4, 0.65, 0, 0.18, 0.35, 6)
    # Head
    o.sphere(0.55, 0.9, 0, 0.22, 6, 5)
    # Horn
    o.cone(0.5, 1.15, 0, 0.05, 0.3, 5)
    o.cone(0.6, 1.15, 0, 0.05, 0.25, 5)
    # Mane
    o.cyl(0.35, 0.75, -0.08, 0.08, 0.25, 5, top=False)
    o.cyl(0.25, 0.7, -0.1, 0.06, 0.2, 5, top=False)
    # Legs (4)
    for lx in [-0.25, 0.25]:
        for lz in [-0.2, 0.2]:
            o.cyl(lx, 0.2, lz, 0.08, 0.4, 5)
            o.sphere(lx, 0, lz, 0.1, 4, 3)
    # Tail
    o.cyl(-0.65, 0.55, 0, 0.05, 0.4, 5, top=False)
    o.cone(-0.75, 0.65, 0, 0.08, 0.2, 5)
    # Scales/dorsal fin
    for i in range(4):
        sx = -0.3 + i * 0.2
        o.cone(sx, 0.95, 0, 0.06, 0.15, 4)
    o.save(f"{OUTPUT_DIR}/qilin.obj")

def make_fenghuang():
    """凤凰 - phoenix"""
    o = OBJ("Fenghuang 凤凰")
    # Body (bird-like)
    o.sphere(0, 0.55, 0, 0.3, 6, 5)
    o.cyl(-0.25, 0.5, 0, 0.2, 0.35, 6)
    # Neck
    o.cyl(0.25, 0.65, 0, 0.1, 0.35, 6)
    # Head
    o.sphere(0.35, 0.95, 0, 0.13, 6, 5)
    # Beak
    o.cone(0.45, 0.95, 0, 0.03, 0.15, 4)
    # Crest
    o.cone(0.32, 1.1, 0, 0.03, 0.18, 4)
    o.cone(0.38, 1.08, 0, 0.025, 0.12, 4)
    # Wings (spread)
    o.cyl(-0.15, 0.55, -0.35, 0.06, 0.7, 5, top=False)
    o.cyl(-0.15, 0.55, 0.35, 0.06, 0.7, 5, top=False)
    # Wing tips
    o.sphere(-0.15, 0.6, -0.7, 0.08, 4, 4)
    o.sphere(-0.15, 0.6, 0.7, 0.08, 4, 4)
    # Tail feathers (long flowing)
    for i in range(5):
        angle = -0.3 + i * 0.15
        tx = -0.45 - i * 0.12
        o.cyl(tx, 0.55 + i*0.02, angle, 0.025, 1.2 - i*0.1, 4, top=False)
    # Legs
    o.cyl(-0.1, 0.2, -0.05, 0.04, 0.4, 4)
    o.cyl(0.1, 0.2, 0.05, 0.04, 0.4, 4)
    o.sphere(-0.1, 0, -0.05, 0.05, 4, 3)
    o.sphere(0.1, 0, 0.05, 0.05, 4, 3)
    o.save(f"{OUTPUT_DIR}/fenghuang.obj")

def make_spirit_tiger():
    """灵虎 - spirit tiger"""
    o = OBJ("Spirit Tiger 灵虎")
    # Body
    o.cyl(0, 0.4, 0, 0.35, 1.0, 8)
    o.sphere(-0.35, 0.4, 0, 0.28, 6, 5)
    o.sphere(0.5, 0.45, 0, 0.35, 6, 5)
    # Head
    o.sphere(0.75, 0.6, 0, 0.25, 6, 5)
    # Ears
    o.sphere(0.72, 0.85, -0.1, 0.08, 4, 3)
    o.sphere(0.72, 0.85, 0.1, 0.08, 4, 3)
    # Snout
    o.cyl(0.9, 0.55, 0, 0.12, 0.2, 6)
    # Legs (4)
    for lx in [-0.3, 0.2]:
        for lz in [-0.18, 0.18]:
            o.cyl(lx, 0.15, lz, 0.08, 0.3, 5)
            o.sphere(lx, -0.02, lz, 0.1, 4, 3)
    # Tail
    o.cyl(-0.6, 0.45, 0, 0.06, 0.6, 5, top=False)
    # Spirit markings (simplified as raised areas)
    o.sphere(0.1, 0.6, -0.2, 0.06, 4, 3)
    o.sphere(0.1, 0.6, 0.2, 0.06, 4, 3)
    o.sphere(-0.15, 0.55, -0.18, 0.05, 4, 3)
    o.sphere(-0.15, 0.55, 0.18, 0.05, 4, 3)
    o.save(f"{OUTPUT_DIR}/spirit_tiger.obj")

def make_spirit_crane():
    """仙鹤 - immortal crane"""
    o = OBJ("Spirit Crane 仙鹤")
    # Body
    o.sphere(0, 0.4, 0, 0.22, 6, 5)
    # Neck (long and curved)
    neck_pts = [
        (0.1, 0.5, 0), (0.15, 0.65, 0), (0.2, 0.8, 0), 
        (0.22, 0.95, 0), (0.2, 1.1, 0)
    ]
    for x, y, z in neck_pts:
        o.sphere(x, y, z, 0.08, 5, 4)
    # Head
    o.sphere(0.18, 1.2, 0, 0.1, 5, 4)
    # Beak
    o.cone(0.28, 1.2, 0, 0.02, 0.15, 4)
    # Red crown
    o.sphere(0.16, 1.3, 0, 0.04, 4, 3)
    # Wings (folded)
    o.cyl(-0.05, 0.4, -0.3, 0.05, 0.5, 5, top=False)
    o.cyl(-0.05, 0.4, 0.3, 0.05, 0.5, 5, top=False)
    # Tail feathers
    for i in range(4):
        o.cyl(-0.2 - i*0.08, 0.38, 0, 0.02, 0.35 - i*0.05, 4, top=False)
    # Legs (long)
    o.cyl(-0.05, 0.15, -0.05, 0.02, 0.35, 4)
    o.cyl(0.05, 0.15, 0.05, 0.02, 0.35, 4)
    o.sphere(-0.05, -0.2, -0.05, 0.04, 4, 3)
    o.sphere(0.05, -0.2, 0.05, 0.04, 4, 3)
    o.save(f"{OUTPUT_DIR}/spirit_crane.obj")

# ============================================================
# Run all generators
# ============================================================
if __name__ == "__main__":
    print("=== 修仙角色与灵兽3D模型生成器 ===\n")
    print("【修士角色】")
    make_cultivator_male()
    make_cultivator_female()
    make_sword_cultivator()
    make_alchemist()
    make_body_cultivator()
    make_elder()
    print("\n【灵兽】")
    make_qilin()
    make_fenghuang()
    make_spirit_tiger()
    make_spirit_crane()
    print(f"\n✅ 所有角色模型已保存到 {OUTPUT_DIR}/")
