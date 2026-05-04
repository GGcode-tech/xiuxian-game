# 修仙家族模拟器 🏔️🧘

> 基于 Godot 4.x 的修仙家族模拟经营游戏

## 项目结构

```
xiuxian_game/
├── project.godot                 # 项目配置
├── README.md                     # 本文件
├── autoload/                     # 全局单例
│   ├── game_manager.gd           # 游戏管理器（时间/状态/速度）
│   ├── data_manager.gd           # 数据管理器（配置数据加载）
│   ├── event_manager.gd          # 事件管理器（随机事件/通知）
│   ├── save_manager.gd           # 存档管理器（多存档/自动存档）
│   └── audio_manager.gd          # 音频管理器（BGM/SFX）
├── data/                         # 数据资源
│   ├── realms/                   # 境界数据
│   │   ├── realm_data.gd         # 境界数据类定义
│   │   ├── realm_1_refining_qi.tres     # 炼气期
│   │   ├── realm_2_foundation.tres      # 筑基期
│   │   ├── realm_3_core_formation.tres  # 结丹期
│   │   ├── realm_4_nascent_soul.tres    # 元婴期
│   │   ├── realm_5_spirit_transformation.tres  # 化神期
│   │   ├── realm_6_void_refining.tres   # 炼虚期
│   │   ├── realm_7_body_integration.tres # 合体期
│   │   ├── realm_8_mahayana.tres        # 大乘期
│   │   ├── realm_9_tribulation.tres     # 渡劫期
│   │   └── realm_10_ascension.tres      # 飞升
│   ├── techniques/               # 功法数据
│   │   ├── technique_data.gd     # 功法数据类
│   │   ├── skill_data.gd         # 技能数据类
│   │   ├── tech_five_elements_art.tres   # 五行归元诀
│   │   ├── tech_azure_essence_art.tres   # 青元剑诀
│   │   ├── tech_heavenly_fire_art.tres   # 天火焚天诀
│   │   ├── tech_ice_soul_art.tres        # 冰魄寒光诀
│   │   ├── tech_body_refining_art.tres   # 金刚不灭体
│   │   ├── tech_soul_refining_art.tres   # 神识淬炼法
│   │   ├── tech_beast_taming_art.tres    # 万兽归心诀
│   │   ├── tech_sword_intent_art.tres    # 万剑归宗
│   │   └── tech_formation_art.tres       # 天机阵法
│   ├── items/                    # 物品数据
│   │   ├── item_data.gd          # 物品数据类
│   │   ├── item_spirit_gathering_pill.tres  # 聚灵丹
│   │   ├── item_foundation_pill.tres         # 筑基丹
│   │   ├── item_healing_pill.tres            # 回春丹
│   │   ├── item_spirit_recovery_pill.tres    # 归元丹
│   │   ├── item_golden_core_pill.tres        # 结金丹
│   │   ├── item_spirit_grass.tres            # 灵草
│   │   ├── item_fire_spirit_grass.tres       # 火灵草
│   │   ├── item_ice_lotus.tres               # 冰莲
│   │   ├── item_spirit_ore.tres              # 灵矿
│   │   ├── item_blood_essence_stone.tres     # 精血石
│   │   ├── item_spirit_sword.tres            # 灵剑
│   │   ├── item_spirit_armor.tres            # 灵甲
│   │   ├── item_storage_ring.tres            # 储物戒
│   │   ├── item_thunder_sword.tres           # 雷鸣剑
│   │   ├── item_scroll_basic_cultivation.tres # 基础修炼法
│   │   └── item_golden_sun_bead.tres         # 金阳珠
│   ├── events/                   # 事件数据
│   │   ├── event_data.gd         # 事件数据类
│   │   ├── event_choice.gd       # 事件选项类
│   │   ├── event_outcome.gd      # 事件结果类
│   │   ├── event_spirit_root_awakening.tres  # 灵根觉醒
│   │   ├── event_ancient_cave_discovery.tres # 上古洞府
│   │   ├── event_family_crisis.tres           # 家族危机
│   │   ├── event_marriage_proposal.tres       # 联姻之议
│   │   └── event_rare_herb_found.tres         # 天材地宝
│   └── constants/
│       └── game_constants.gd     # 游戏常量配置
├── scripts/                      # 系统脚本
│   ├── systems/
│   │   ├── character.gd          # 角色类（修炼/突破/战斗/物品）
│   │   ├── family.gd             # 家族类（资源/成员/关系/继承）
│   │   ├── item_instance.gd      # 物品实例（强化/词缀/耐久）
│   │   ├── map_data.gd           # 地图数据（领地/宗门/资源点）
│   │   ├── status_effect.gd      # 状态效果（增益/减益/DOT/HOT）
│   │   ├── alchemy_system.gd     # 炼丹系统
│   │   └── combat_system.gd      # 战斗系统（回合制）
│   └── utils/
│       ├── character_generator.gd # 角色生成器
│       └── game_starter.gd       # 游戏启动器
├── scenes/                       # 场景
│   ├── main/
│   │   └── main_scene.gd         # 主场景
│   └── world/
│       └── world.gd              # 世界节点
└── ui/                           # UI组件
    ├── hud.gd                    # HUD主界面
    ├── character_panel.gd        # 角色面板
    ├── family_panel.gd           # 家族面板
    └── notification_system.gd    # 通知系统
```

## 境界体系

| 等级 | 境界 | 突破率 | 寿命加成 | 特点 |
|------|------|--------|----------|------|
| 1 | 炼气期 | 90% | +50 | 感应灵气，13层 |
| 2 | 筑基期 | 70% | +100 | 凝聚根基，4阶段 |
| 3 | 结丹期 | 50% | +200 | 结金丹，可飞行 |
| 4 | 元婴期 | 30% | +500 | 孕元婴，操控法宝 |
| 5 | 化神期 | 20% | +1000 | 化神通，操控天地 |
| 6 | 炼虚期 | 15% | +2000 | 炼虚空，开辟小世界 |
| 7 | 合体期 | 10% | +3000 | 身道合，法力无边 |
| 8 | 大乘期 | 7% | +5000 | 大乘道，万法归宗 |
| 9 | 渡劫期 | 3% | +8000 | 渡天劫，超脱轮回 |
| 10 | 飞升 | 1% | +99999 | 升仙界，全新体系 |

## 功法体系

| 功法 | 类型 | 品质 | 灵根要求 | 特色 |
|------|------|------|----------|------|
| 五行归元诀 | 主功法 | ★★★ | 五行齐全 | 五行相生循环 |
| 青元剑诀 | 主功法 | ★★★ | 木≥0.5 | 剑意入道 |
| 天火焚天诀 | 主功法 | ★★★★ | 火≥0.6 | 引天火入体 |
| 冰魄寒光诀 | 主功法 | ★★★ | 水≥0.5 | 冻结万物 |
| 金刚不灭体 | 炼体 | ★★★★ | 土≥0.3 | 肉身万法不侵 |
| 神识淬炼法 | 神识 | ★★★ | 无 | 增强神识 |
| 万兽归心诀 | 主功法 | ★★★ | 木≥0.3 | 驯服灵兽 |
| 万剑归宗 | 战斗 | ★★★★★ | 金≥0.6 | 至高剑道 |
| 天机阵法 | 辅助 | ★★★ | 无 | 精通阵法 |

## 操作按键

| 按键 | 功能 |
|------|------|
| Space | 切换游戏速度 |
| Esc | 暂停/恢复 |
| Ctrl+S | 快速存档 |
| Ctrl+L | 快速读档 |

## 技术栈

- **引擎**: Godot 4.3+
- **语言**: GDScript
- **架构**: Autoload全局单例 + Resource数据配置 + Signal事件驱动
- **目标**: PC (Steam) / 移动端

## 开发状态

- [x] 项目结构搭建
- [x] 核心数据类定义
- [x] 全局管理器实现
- [x] 境界体系数据 (10境)
- [x] 功法体系数据 (9种)
- [x] 物品体系数据 (16种)
- [x] 事件系统数据 (5种)
- [x] 角色系统（修炼/突破/物品/战斗）
- [x] 家族系统（资源/成员/关系/继承）
- [x] 炼丹系统
- [x] 战斗系统（回合制）
- [x] 状态效果系统
- [x] 地图系统
- [x] 角色生成器
- [x] UI组件框架
- [ ] 3D场景和模型
- [ ] 音效和音乐
- [ ] 完整UI布局（.tscn场景文件）
- [ ] 美术资源
- [ ] 平衡性调优
- [ ] 测试和调试
