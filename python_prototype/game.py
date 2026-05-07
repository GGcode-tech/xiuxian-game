#!/usr/bin/env python3
"""
修仙家族模拟器 - Python 终端原型
核心游戏循环验证

基于 Godot 4.x 项目的核心逻辑移植
"""

import random
import time
import json
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
from enum import Enum

# ==================== 常量配置 ====================

REALMS = [
    {"id": "refining_qi", "name": "炼气期", "tier": 1, "required_exp": 100, 
     "breakthrough_rate": 0.90, "hp_bonus": 50, "mp_bonus": 30,
     "attack_bonus": 5, "defense_bonus": 3, "spirit_bonus": 5,
     "lifespan_bonus": 50},
    {"id": "foundation", "name": "筑基期", "tier": 2, "required_exp": 500,
     "breakthrough_rate": 0.75, "hp_bonus": 150, "mp_bonus": 100,
     "attack_bonus": 15, "defense_bonus": 10, "spirit_bonus": 15,
     "lifespan_bonus": 150},
    {"id": "core_formation", "name": "结丹期", "tier": 3, "required_exp": 2000,
     "breakthrough_rate": 0.60, "hp_bonus": 400, "mp_bonus": 300,
     "attack_bonus": 40, "defense_bonus": 30, "spirit_bonus": 40,
     "lifespan_bonus": 400},
    {"id": "nascent_soul", "name": "元婴期", "tier": 4, "required_exp": 8000,
     "breakthrough_rate": 0.50, "hp_bonus": 1000, "mp_bonus": 800,
     "attack_bonus": 100, "defense_bonus": 80, "spirit_bonus": 100,
     "lifespan_bonus": 1000},
    {"id": "spirit_transformation", "name": "化神期", "tier": 5, "required_exp": 30000,
     "breakthrough_rate": 0.40, "hp_bonus": 2500, "mp_bonus": 2000,
     "attack_bonus": 250, "defense_bonus": 200, "spirit_bonus": 250,
     "lifespan_bonus": 2500},
    {"id": "void_refining", "name": "炼虚期", "tier": 6, "required_exp": 100000,
     "breakthrough_rate": 0.30, "hp_bonus": 6000, "mp_bonus": 5000,
     "attack_bonus": 600, "defense_bonus": 500, "spirit_bonus": 600,
     "lifespan_bonus": 6000},
    {"id": "body_integration", "name": "合体期", "tier": 7, "required_exp": 400000,
     "breakthrough_rate": 0.25, "hp_bonus": 15000, "mp_bonus": 12000,
     "attack_bonus": 1500, "defense_bonus": 1200, "spirit_bonus": 1500,
     "lifespan_bonus": 15000},
    {"id": "mahayana", "name": "大乘期", "tier": 8, "required_exp": 1000000,
     "breakthrough_rate": 0.20, "hp_bonus": 40000, "mp_bonus": 35000,
     "attack_bonus": 4000, "defense_bonus": 3500, "spirit_bonus": 4000,
     "lifespan_bonus": 40000},
    {"id": "tribulation", "name": "渡劫期", "tier": 9, "required_exp": 5000000,
     "breakthrough_rate": 0.15, "hp_bonus": 100000, "mp_bonus": 80000,
     "attack_bonus": 10000, "defense_bonus": 8000, "spirit_bonus": 10000,
     "lifespan_bonus": 100000},
    {"id": "ascension", "name": "飞升期", "tier": 10, "required_exp": 99999999,
     "breakthrough_rate": 0.10, "hp_bonus": 999999, "mp_bonus": 999999,
     "attack_bonus": 99999, "defense_bonus": 99999, "spirit_bonus": 99999,
     "lifespan_bonus": 999999},
]

TECHNIQUES = [
    {"id": "basic_cultivation", "name": "基础修炼法", "type": "cultivation",
     "speed_bonus": 1.0, "stat_bonus": {"attack": 5}},
    {"id": "five_elements", "name": "五行功法", "type": "cultivation",
     "speed_bonus": 1.3, "stat_bonus": {"attack": 15, "defense": 10}},
    {"id": "soul_refining", "name": "炼神诀", "type": "soul",
     "speed_bonus": 1.2, "stat_bonus": {"spirit": 20}},
    {"id": "body_refining", "name": "炼体诀", "type": "body",
     "speed_bonus": 1.1, "stat_bonus": {"max_hp": 100, "defense": 15}},
    {"id": "sword_intent", "name": "剑意诀", "type": "combat",
     "speed_bonus": 1.0, "stat_bonus": {"attack": 30}},
    {"id": "azure_essence", "name": "青云诀", "type": "cultivation",
     "speed_bonus": 1.5, "stat_bonus": {"spirit": 15, "max_mp": 50}},
]

SURNAMES = ["韩", "萧", "林", "陈", "张", "王", "李", "周", "吴", "郑", "叶", "方", "南宫", "欧阳", "司马"]
GIVEN_NAMES_MALE = ["立", "云", "风", "羽", "雷", "寒", "尘", "逸", "仙", "道", "天", "玄", "墨", "青", "玉"]
GIVEN_NAMES_FEMALE = ["婉", "月", "霜", "雪", "灵", "儿", "竹", "兰", "婷", "欣", "倩", "雅", "琳", "萱", "瑶"]

# ==================== 数据类 ====================

@dataclass
class Character:
    """角色数据类 - 对应 Godot Character.gd"""
    id: str
    name: str
    gender: int  # 0=男, 1=女
    age: int = 25
    realm_exp: int = 0
    realm_index: int = 0  # 当前境界索引
    spirit_root: Dict[str, float] = field(default_factory=dict)
    bloodline_purity: float = 0.0
    techniques: List[str] = field(default_factory=list)
    family_id: str = ""
    generation: int = 1
    
    # 基础属性
    base_hp: int = 100
    base_mp: int = 50
    base_attack: int = 10
    base_defense: int = 5
    base_spirit: int = 10
    
    # 当前状态
    hp: int = 100
    mp: int = 50
    is_alive: bool = True
    lifespan: int = 80
    
    # 背包
    inventory: Dict[str, int] = field(default_factory=dict)
    
    def __post_init__(self):
        if not self.spirit_root:
            self.spirit_root = {
                "gold": random.uniform(0.1, 1.0),
                "wood": random.uniform(0.1, 1.0),
                "water": random.uniform(0.1, 1.0),
                "fire": random.uniform(0.1, 1.0),
                "earth": random.uniform(0.1, 1.0),
            }
    
    @property
    def realm(self) -> Dict:
        return REALMS[self.realm_index]
    
    @property
    def max_hp(self) -> int:
        return self.base_hp + self.realm["hp_bonus"]
    
    @property
    def max_mp(self) -> int:
        return self.base_mp + self.realm["mp_bonus"]
    
    @property
    def attack(self) -> int:
        return self.base_attack + self.realm["attack_bonus"]
    
    @property
    def defense(self) -> int:
        return self.base_defense + self.realm["defense_bonus"]
    
    @property
    def spirit(self) -> int:
        return self.base_spirit + self.realm["spirit_bonus"]
    
    @property
    def spirit_root_desc(self) -> str:
        """灵根描述"""
        roots = []
        for elem, val in self.spirit_root.items():
            if val > 0.7:
                roots.append(f"{elem}(极好)")
            elif val > 0.5:
                roots.append(f"{elem}(良)")
            elif val > 0.3:
                roots.append(f"{elem}(中)")
        return ", ".join(roots) if roots else "无"
    
    def process_daily(self) -> None:
        """每日修炼 - 对应 Godot process_daily()"""
        if not self.is_alive:
            return
        
        # 计算修炼经验
        base_exp = 10
        base_exp += self.spirit * 0.5
        
        # 功法加成
        for tech_id in self.techniques:
            tech = next((t for t in TECHNIQUES if t["id"] == tech_id), None)
            if tech:
                base_exp *= tech["speed_bonus"]
        
        # 灵根加成
        spirit_avg = sum(self.spirit_root.values()) / 5
        base_exp *= (1.0 + spirit_avg * 0.5)
        
        # 血脉加成
        base_exp *= (1.0 + self.bloodline_purity * 0.3)
        
        self.realm_exp += int(base_exp)
        
        # 恢复
        self.hp = min(self.hp + 10, self.max_hp)
        self.mp = min(self.mp + 5, self.max_mp)
    
    def can_breakthrough(self) -> bool:
        """检查是否可以突破"""
        if self.realm_index >= len(REALMS) - 1:
            return False
        return self.realm_exp >= self.realm["required_exp"]
    
    def attempt_breakthrough(self) -> Dict[str, Any]:
        """尝试突破 - 对应 Godot attempt_breakthrough()"""
        if self.realm_index >= len(REALMS) - 1:
            return {"success": False, "reason": "已达最高境界"}
        
        if not self.can_breakthrough():
            return {"success": False, "reason": f"经验不足 ({self.realm_exp}/{self.realm['required_exp']})"}
        
        # 计算成功率
        rate = self.realm["breakthrough_rate"]
        rate += self.bloodline_purity * 0.1
        spirit_max = max(self.spirit_root.values())
        rate += spirit_max * 0.05
        rate = min(rate, 0.95)
        
        # 消耗经验
        self.realm_exp = 0
        
        # 判定结果
        roll = random.random()
        if roll <= rate:
            self.realm_index += 1
            self.lifespan += self.realm["lifespan_bonus"]
            self.hp = self.max_hp
            self.mp = self.max_mp
            return {
                "success": True,
                "realm": self.realm["name"],
                "rate": rate,
                "roll": roll
            }
        else:
            # 失败惩罚
            if random.random() < 0.2:
                damage = int(self.max_hp * 0.3)
                self.hp -= damage
                if self.hp <= 0:
                    self.die("突破失败重伤")
                    return {"success": False, "reason": "突破失败重伤", "roll": roll}
                return {"success": False, "reason": f"突破失败受伤(-{damage}HP)", "roll": roll}
            return {"success": False, "reason": "突破失败", "roll": roll}
    
    def die(self, reason: str = "") -> None:
        """死亡"""
        self.is_alive = False
        self.hp = 0
    
    def learn_technique(self, tech_id: str) -> bool:
        """学习功法"""
        if tech_id in self.techniques:
            return False
        self.techniques.append(tech_id)
        return True
    
    def status(self) -> str:
        """状态描述"""
        status = f"{'存活' if self.is_alive else '死亡'} | "
        status += f"{self.realm['name']} | "
        status += f"经验:{self.realm_exp}/{self.realm['required_exp']} | "
        status += f"HP:{self.hp}/{self.max_hp} MP:{self.mp}/{self.max_mp} | "
        status += f"年龄:{self.age}岁 寿元:{self.lifespan} | "
        status += f"攻击:{self.attack} 防御:{self.defense} 神识:{self.spirit}"
        return status


@dataclass
class Family:
    """家族数据类"""
    id: str
    name: str
    founder_id: str
    members: List[str] = field(default_factory=list)
    resources: Dict[str, int] = field(default_factory=lambda: {
        "spirit_stone": 1000,
        "elixir": 5,
        "herb": 20,
    })
    prestige: int = 100  # 声望
    founded_year: int = 1


class GameManager:
    """游戏管理器 - 对应 Godot GameManager"""
    
    def __init__(self):
        self.game_time = {"year": 1, "month": 1, "day": 1}
        self.characters: Dict[str, Character] = {}
        self.families: Dict[str, Family] = {}
        self.player_family_id: str = ""
        self.game_speed: float = 1.0
        self.is_paused: bool = False
        self.is_started: bool = False
        self.day_counter: int = 0
    
    def start_new_game(self, family_name: str = "修仙世家", founder_name: str = "") -> Family:
        """开始新游戏"""
        self.game_time = {"year": 1, "month": 1, "day": 1}
        self.day_counter = 0
        self.is_started = True
        self.is_paused = False
        self.characters = {}
        self.families = {}
        
        # 创建角色
        if not founder_name:
            founder_name = self._generate_name(0)
        
        founder = Character(
            id="char_1",
            name=founder_name,
            gender=random.randint(0, 1),
            age=25,
            realm_index=0,
        )
        founder.learn_technique("basic_cultivation")
        founder.family_id = "family_1"
        
        self.characters[founder.id] = founder
        
        # 创建家族
        family = Family(
            id="family_1",
            name=family_name,
            founder_id=founder.id,
        )
        family.members.append(founder.id)
        self.families[family.id] = family
        self.player_family_id = family.id
        
        return family
    
    def _generate_name(self, gender: int) -> str:
        """生成随机名字"""
        surname = random.choice(SURNAMES)
        given = random.choice(GIVEN_NAMES_FEMALE if gender == 1 else GIVEN_NAMES_MALE)
        return surname + given
    
    def advance_day(self) -> None:
        """推进一天"""
        self.day_counter += 1
        self.game_time["day"] += 1
        
        # 月份结束
        if self.game_time["day"] > 30:
            self.game_time["day"] = 1
            self.game_time["month"] += 1
        
        # 年份结束
        if self.game_time["month"] > 12:
            self.game_time["month"] = 1
            self.game_time["year"] += 1
        
        # 处理所有角色
        for char in self.characters.values():
            if char.is_alive:
                char.age += 1
                char.process_daily()
                
                # 检查寿命
                if char.age > char.lifespan:
                    if random.random() < 0.3:
                        char.die("寿元耗尽")
                        print(f"  💀 {char.name} 寿元耗尽，享年{char.age}岁")
    
    def get_time_str(self) -> str:
        return f"第{self.game_time['year']}年 {self.game_time['month']}月 {self.game_time['day']}日"
    
    def list_characters(self, family_id: str = "") -> List[Character]:
        """列出角色"""
        if family_id:
            return [c for c in self.characters.values() if c.family_id == family_id and c.is_alive]
        return [c for c in self.characters.values() if c.is_alive]
    
    def add_character(self, char: Character) -> None:
        self.characters[char.id] = char
    
    def generate_descendant(self, parent: Character, spouse: Optional[Character] = None) -> Character:
        """生成后代"""
        new_id = f"char_{len(self.characters) + 1}"
        
        # 继承灵根
        child_root = {}
        for elem in parent.spirit_root:
            child_root[elem] = parent.spirit_root[elem] * 0.5 + random.uniform(0, 0.5)
            child_root[elem] = min(child_root[elem], 1.0)
        
        child = Character(
            id=new_id,
            name=self._generate_name(random.randint(0, 1)),
            gender=random.randint(0, 1),
            age=0,
            realm_index=0,
            spirit_root=child_root,
            bloodline_purity=parent.bloodline_purity * 0.8,
            family_id=parent.family_id,
            generation=parent.generation + 1,
        )
        child.learn_technique("basic_cultivation")
        
        self.characters[child.id] = child
        
        family = self.families.get(parent.family_id)
        if family:
            family.members.append(child.id)
        
        return child


# ==================== 游戏界面 ====================

class GameUI:
    """终端游戏界面"""
    
    def __init__(self):
        self.game = GameManager()
        self.running = True
    
    def clear_screen(self):
        print("\033[2J\033[H", end="")  # 清屏
    
    def print_header(self, title: str):
        print(f"\n{'='*60}")
        print(f"  🎮 {title}")
        print(f"{'='*60}")
    
    def print_status_bar(self):
        """打印状态栏"""
        family = self.game.families.get(self.game.player_family_id)
        alive_chars = self.game.list_characters(self.game.player_family_id)
        
        print(f"\n{'─'*60}")
        print(f"  ⏰ {self.game.get_time_str()} | 速度:{self.game.game_speed}x | {'⏸️暂停' if self.game.is_paused else '▶️运行'}")
        print(f"  🏠 家族: {family.name if family else '?'} | 成员:{len(alive_chars)}人 | 灵石:{family.resources.get('spirit_stone', 0) if family else 0}")
        print(f"{'─'*60}")
    
    def menu_main(self):
        """主菜单"""
        self.clear_screen()
        self.print_header("修仙家族模拟器 v0.1")
        print("  基于 Godot 4.x 项目核心逻辑的 Python 原型验证")
        print()
        print("  [1] 🚀 开始新游戏")
        print("  [2] 📖 继续游戏")
        print("  [3] ❌ 退出")
        print()
        choice = input("  请选择: ").strip()
        
        if choice == "1":
            self.menu_new_game()
        elif choice == "3":
            self.running = False
    
    def menu_new_game(self):
        """新游戏菜单"""
        self.clear_screen()
        self.print_header("新游戏")
        
        family_name = input("  家族名称 (直接回车默认'修仙世家'): ").strip()
        if not family_name:
            family_name = "修仙世家"
        
        founder_name = input("  族长姓名 (直接回车随机): ").strip()
        
        family = self.game.start_new_game(family_name, founder_name if founder_name else "")
        founder = self.game.characters[family.founder_id]
        
        self.clear_screen()
        print(f"\n  ✅ 游戏开始！")
        print(f"  🏠 {family.name} 创立")
        print(f"  👤 族长: {founder.name}")
        print(f"  🌀 境界: {founder.realm['name']}")
        print(f"  📊 灵根: {founder.spirit_root_desc}")
        input("\n  按回车继续...")
        
        self.menu_game()
    
    def menu_game(self):
        """游戏主界面"""
        while self.running and self.game.is_started:
            self.clear_screen()
            self.print_header("修仙家族模拟器")
            self.print_status_bar()
            
            # 显示角色列表
            chars = self.game.list_characters(self.game.player_family_id)
            print(f"\n  📜 家族成员 ({len(chars)}人):")
            print(f"  {'─'*56}")
            for i, char in enumerate(chars, 1):
                bt_marker = " ⭐可突破" if char.can_breakthrough() else ""
                print(f"  {i}. {char.name} | {char.realm['name']} | {char.realm_exp}/{char.realm['required_exp']}{bt_marker}")
                print(f"     HP:{char.hp}/{char.max_hp} MP:{char.mp}/{char.max_mp} | 年龄:{char.age}岁 | 攻击:{char.attack} 防御:{char.defense}")
            
            print(f"\n  {'─'*56}")
            print("  [1] ⏭️  推进1天   [2] ⏩ 推进30天   [3] ⏭️⏭️ 推进1年")
            print("  [4] 🔍 角色详情  [5] 💫 尝试突破   [6] ⚙️  设置速度")
            print("  [7] 👶 添加入侵者 [8] 📊 统计数据   [0] 🚪 退出")
            
            choice = input("\n  请选择: ").strip()
            
            if choice == "1":
                self.game.advance_day()
            elif choice == "2":
                for _ in range(30):
                    self.game.advance_day()
            elif choice == "3":
                for _ in range(365):
                    self.game.advance_day()
            elif choice == "4":
                self.menu_character_detail()
            elif choice == "5":
                self.menu_breakthrough()
            elif choice == "6":
                self.menu_speed()
            elif choice == "7":
                self.add_intruder()
            elif choice == "8":
                self.show_stats()
            elif choice == "0":
                self.game.is_started = False
    
    def menu_character_detail(self):
        """角色详情"""
        chars = self.game.list_characters(self.game.player_family_id)
        print("\n  选择角色编号查看详情 (0返回): ", end="")
        try:
            idx = int(input().strip()) - 1
            if idx < 0 or idx >= len(chars):
                return
            char = chars[idx]
            
            self.clear_screen()
            print(f"\n{'='*60}")
            print(f"  👤 {char.name}")
            print(f"{'='*60}")
            print(f"  性别: {'女' if char.gender else '男'}")
            print(f"  年龄: {char.age}岁 | 寿元: {char.lifespan}")
            print(f"  辈分: 第{char.generation}代")
            print()
            print(f"  🌀 当前境界: {char.realm['name']} (第{char.realm['tier']}境)")
            print(f"  📈 修炼进度: {char.realm_exp}/{char.realm['required_exp']} 经验")
            print(f"  📊 突破率: {char.realm['breakthrough_rate']*100:.0f}%")
            print()
            print(f"  五行灵根:")
            for elem, val in char.spirit_root.items():
                bar = "█" * int(val * 10) + "░" * (10 - int(val * 10))
                print(f"    {elem}: {bar} {val:.2f}")
            print(f"  血脉纯度: {char.bloodline_purity:.2f}")
            print()
            print(f"  功法: {', '.join(char.techniques) if char.techniques else '无'}")
            print()
            print(f"  HP: {char.hp}/{char.max_hp}")
            print(f"  MP: {char.mp}/{char.max_mp}")
            print(f"  攻击: {char.attack} | 防御: {char.defense} | 神识: {char.spirit}")
            print(f"{'='*60}")
            input("\n  按回车返回...")
        except ValueError:
            pass
    
    def menu_breakthrough(self):
        """突破界面"""
        chars = self.game.list_characters(self.game.player_family_id)
        
        # 筛选可突破角色
        breakable = [(i, c) for i, c in enumerate(chars) if c.can_breakthrough()]
        
        if not breakable:
            print("\n  ⚠️ 没有角色满足突破条件")
            input("\n  按回车返回...")
            return
        
        print("\n  可突破角色:")
        for i, (idx, char) in enumerate(breakable, 1):
            print(f"    {i}. {char.name} - {char.realm['name']} → {REALMS[char.realm_index+1]['name']}")
        
        print("\n  选择角色 (0返回): ", end="")
        try:
            choice = int(input().strip()) - 1
            if choice < 0 or choice >= len(breakable):
                return
            
            _, char = breakable[choice]
            print(f"\n  🎲 {char.name} 尝试突破 {char.realm['name']} → {REALMS[char.realm_index+1]['name']}...")
            time.sleep(1)
            
            result = char.attempt_breakthrough()
            
            if result["success"]:
                print(f"\n  ✨✅ 突破成功！进入 {result['realm']}！")
                print(f"     (概率:{result['rate']*100:.0f}% 骰出:{result['roll']*100:.1f}%)")
            else:
                print(f"\n  💥❌ {result['reason']}")
                print(f"     (概率:{char.realm['breakthrough_rate']*100:.0f}% 骰出:{result['roll']*100:.1f}%)")
            
            input("\n  按回车返回...")
        except ValueError:
            pass
    
    def menu_speed(self):
        """速度设置"""
        print("\n  当前速度: {:.1f}x".format(self.game.game_speed))
        print("  [1] 0.5x (慢速)")
        print("  [2] 1.0x (正常)")
        print("  [3] 2.0x (快速)")
        print("  [4] 5.0x (极快)")
        print("  [5] 10.0x (挂机)")
        print("  [0] 返回")
        
        speeds = {"1": 0.5, "2": 1.0, "3": 2.0, "4": 5.0, "5": 10.0}
        choice = input("\n  请选择: ").strip()
        if choice in speeds:
            self.game.game_speed = speeds[choice]
    
    def add_intruder(self):
        """添加随机入侵者/外门弟子"""
        family = self.game.families.get(self.game.player_family_id)
        if not family:
            return
        
        # 随机生成一个外来者
        intruder = Character(
            id=f"char_{len(self.game.characters) + 1}",
            name=self.game._generate_name(random.randint(0, 1)),
            gender=random.randint(0, 1),
            age=random.randint(18, 40),
            realm_index=random.randint(0, 2),  # 低境界
            spirit_root={k: random.uniform(0.2, 0.6) for k in ["gold", "wood", "water", "fire", "earth"]},
            family_id=family.id,
            generation=99,  # 外门弟子
        )
        intruder.learn_technique("basic_cultivation")
        
        self.game.add_character(intruder)
        family.members.append(intruder.id)
        
        print(f"\n  ✅ 添加了 {intruder.name} (外门弟子)")
        print(f"     境界: {intruder.realm['name']}")
        input("\n  按回车返回...")
    
    def show_stats(self):
        """显示统计数据"""
        chars = self.game.list_characters(self.game.player_family_id)
        family = self.game.families.get(self.game.player_family_id)
        
        # 境界分布
        realm_dist = {}
        for char in chars:
            rname = char.realm["name"]
            realm_dist[rname] = realm_dist.get(rname, 0) + 1
        
        self.clear_screen()
        print(f"\n{'='*60}")
        print(f"  📊 {family.name if family else '?'} 家族统计")
        print(f"{'='*60}")
        print(f"  游戏天数: {self.game.day_counter}")
        print(f"  存活成员: {len(chars)}人")
        print(f"  声望: {family.prestige if family else 0}")
        print()
        print(f"  境界分布:")
        for rname, count in sorted(realm_dist.items(), key=lambda x: REALMS.index(next(r for r in REALMS if r["name"]==x[0]))):
            print(f"    {rname}: {count}人")
        print()
        
        # 死亡统计
        dead = [c for c in self.game.characters.values() if not c.is_alive]
        if dead:
            print(f"  已故成员: {len(dead)}人")
        
        print(f"{'='*60}")
        input("\n  按回车返回...")


# ==================== 启动 ====================

def main():
    """主入口"""
    ui = GameUI()
    
    while ui.running:
        ui.menu_main()
    
    print("\n  👋 再见！修仙路漫漫，祝你飞升！\n")


if __name__ == "__main__":
    main()
