# 中世纪轻动作 RPG —— 设计与实现方案

> 版本 v1.4（方向讨论稿）｜目标引擎暂定 **Godot 4.7.2-stable** ｜视角 **2D 45 度斜视（像素风）** ｜战斗 **实时轻动作**
> 现有工程：`godot-game/`（已有 `project.godot`，尚无主场景，需按第 6.1 节改造为 2D 项目）

---

## 目录

- [0. 决策摘要（一页看完）](#0-决策摘要一页看完)
- [1. 产品定位](#1-产品定位)
- [2. 核心循环](#2-核心循环)
- [3. 战斗系统（核心）](#3-战斗系统核心)
- [4. 数值与成长](#4-数值与成长)
- [5. 世界、任务与叙事](#5-世界任务与叙事)
- [6. 技术框架](#6-技术框架)
- [7. 实现流程（垂直切片）](#7-实现流程垂直切片)
- [8. 首个垂直切片日程](#8-首个垂直切片日程)
- [9. 美术与音频资源方案](#9-美术与音频资源方案)
- [10. 风险与常见坑](#10-风险与常见坑)
- [11. 后续扩展路线](#11-后续扩展路线)
- [附录 A. 战斗原型占位数值（待试玩）](#附录-a-战斗原型占位数值待试玩)
- [附录 B. 键鼠输入映射（原型建议）](#附录-b-键鼠输入映射原型建议)
- [附录 C. 碰撞层规划表](#附录-c-碰撞层规划表)
- [附录 D. 事件总线信号清单](#附录-d-事件总线信号清单)
- [附录 E. Godot 4.7 项目设置改动清单](#附录-e-godot-47-项目设置改动清单)

---

## 0. 决策摘要（一页看完）

本节区分了已确认的方向和仍待讨论的设计。未确认的内容不要直接当成开发需求。

| 项目 | 决策 | 理由 |
|---|---|---|
| 核心体验 | **据点出发的室外 Roguelite 探险** | 从安全据点进入开阔的中世纪荒野，完成一局约 15 分钟的探险 |
| 单局长度 | **暂定约 15 分钟** | 当前目标时长；后续通过试玩调整 |
| 单局结束 | **击败最终 Boss 或玩家死亡** | 不设置带普通物品撤离的第三种结束方式 |
| 物品与结算 | 出发时自带的东西保留；局内新获得的普通物品在结局时清空；Boss 胜利保底获得遗物，死亡按概率掉落 | 用遗物而非局内装备搬运推进局外成长 |
| 遗物 | 效果固定设计；随机性只决定掉落哪件；重复遗物转为碎片，购买新遗物或出发加成 | 保留肉鸽变化，同时避免随机奖励沦为废品 |
| 成长 | **局外角色成长 + 局内随机构筑** | 结合 RPG 的长期成长和肉鸽每局变化 |
| 战斗 | **轻松但需要看提示躲招**；当前优先支持键鼠 | 保持休闲门槛，同时让闪避和观察敌人有价值 |
| 世界气质 | **中世纪、偏严肃黑暗，但不要求全程沉重** | 基调可以有温暖、荒诞或人情味的反差 |
| 场景 | **开阔室外区域优先，不以经典地牢为主** | 让探索、路线选择和环境事件成为单局的重要内容 |
| 技术基线 | Godot **4.7.2-stable**、2D 像素风 | 已确认 45 度斜视；tile、方向帧和分辨率仍可由原型验证 |

**一句话定位（暂定）**：一款中世纪像素风轻动作 Roguelite RPG。玩家从据点出发，在开阔荒野中进行约 15 分钟的探险，按路线和速度遇到最终 Boss 或在途中死亡；本局新获得的普通物品不带出，击败 Boss 保底获得遗物，死亡则按概率获得。

**仍待确定**：死亡后的遗物概率、遗物出发配置数量、碎片商品的具体清单、地图随机程度、主角身份与世界危机、恋爱/关系内容、最终平台与开发工期。

---

## 1. 产品定位

### 1.1 参考坐标（找感觉，不抄）

| 参考 | 借什么 |
|---|---|
| 《Hades》 | 单局循环、局内构筑变化与局外成长；场景结构不照搬 |
| 《Death's Door》 | 斜视角动作探索与清晰的环境引导，可参考其节奏而非难度 |
| 《Moonlighter》 | 据点与外出探险形成的往返节奏；经营系统暂不列入首版 |
| 中世纪民间传说与黑暗奇幻作品 | 作为氛围参考；避免默认落入城堡地牢和传统地下迷宫 |

### 1.2 玩家体验目标（体验支柱）

1. **每次出发都值得**：一局约 15 分钟，有清楚的目标、路线选择、遭遇和结算。
2. **结局有代价，也有收获**：死亡或击败最终 Boss 都结束本局；本局新获得的普通物品清空，遗物按概率结算并推动局外成长。
3. **轻松上手，战斗有判断**：操作保持简单；敌人攻击有提示，玩家可以靠走位与闪避应对。
4. **荒野值得探索**：地图以开阔室外环境为主，通过地形、事件、敌人和路线选择制造变化。
5. **成长来自两层**：长期解锁与出发加成提供 RPG 成长感；局内强化让每局形成不同构筑。

### 1.3 反目标（明确不做，写下来是为了防止自己反悔）

- ❌ 不做联机 / 排行榜 / 每日任务
- ❌ 不以经典地牢、地下迷宫作为主要场景
- ❌ 不做无限大、完全随机且难以阅读的地图；优先手制区域，再用路线、遭遇、事件和奖励变化增加重玩性
- ❌ 不做要求精确帧闪避的弹幕式 Boss
- ❌ 不做武器耐久、负重、饥饿度等"反休闲"系统
- ❌ 首个原型不同时铺开大量区域、复杂任务链、恋爱分支和经营系统；这些是否进入正式版本待定

---

## 2. 核心循环

### 2.1 四层循环

```
30 秒循环   发现威胁/机会 → 选择接战或绕行 → 普攻/闪避 → 获得局内资源或强化
   ↓
3–5 分钟段  穿越一片开阔地带 → 遭遇战/事件/补给点 → 选择路线或局内强化
   ↓
约 15 分钟单局  据点整备 → 进入室外区域 → 探索路线、战斗、成长 → 玩家按路线和速度遇到最终 Boss，或提前死亡 → 按结局结算遗物
   ↓
长线循环    带回遗物 → 解锁或强化局外成长/出发加成 → 开启新的路线、事件或挑战 → 再次出发
```

**单局边界原则**：约 15 分钟是目标时长，不是硬倒计时。一局以击败最终 Boss 或玩家死亡结束；玩家探索的路线和速度决定何时遇到 Boss。本局普通物品不带出；击败 Boss 保底获得遗物，死亡按概率掉落。初期用一张手制室外区域，通过遭遇、事件和路线选择验证循环。

### 2.2 每个循环的"奖励钩子"

| 循环 | 必须给的奖励 | 频率 |
|---|---|---|
| 30 秒 | 清晰的命中反馈、少量局内资源或战术空间 | 战斗/探索遭遇 |
| 3–5 分钟 | 一次路线、事件、补给或局内强化选择 | 每个探索段 |
| 单局结算 | Boss 胜利保底获得遗物；死亡显示概率掉落结果 | 每局结束 |
| 长线 | 收藏遗物、重复遗物碎片、局外购买和出发加成 | 每次遗物结算后可规划下一步成长 |

### 2.3 节奏配比（内容设计准则）

| 活动 | 占比（暂定） | 设计目标 |
|---|---|---|
| 战斗 | 35–45% | 单场短促清楚；攻击预警充足，避免连续围攻 |
| 探索/路线选择 | 30–40% | 室外区域开阔易读；路线有风险与奖励差异 |
| 局内构筑/奖励选择 | 15–20% | 少量有意义的选择，不让整理背包打断节奏 |
| 事件/叙事 | 5–15% | 氛围叙事为主，比例与对话长度待定 |

---

## 3. 战斗系统（核心）

> 这一节是整个项目的地基。**先把这里的手感调好，再去做任何其他系统。**

### 3.1 手感三要素：前摇 / 判定 / 后摇

所有攻击动作都拆成三段（单位：秒，按 60 FPS 设计）：

| 动作 | 前摇 Startup | 判定 Active | 后摇 Recovery | 备注 |
|---|---|---|---|---|
| 普攻一段 | 0.10 | 0.08 | 0.16 | 可连下一段 |
| 普攻二段 | 0.12 | 0.08 | 0.18 | |
| 普攻三段 | 0.18 | 0.10 | 0.32 | 击退更强、有屏震 |
| 蓄力重击 | 0.30 | 0.12 | 0.40 | 伤害 ×2.2 |
| 闪避翻滚 | 0.04 | 无敌 0.25 | 0.10 | CD 0.6s，耗体力 25 |
| 技能 A（旋风斩） | 0.15 | 0.35 | 0.30 | CD 6s |
| 技能 B（治疗/护盾） | 0.20 | 瞬时 | 0.25 | CD 15s |

**关键实现技巧**：判定框的开关**不要用代码计时**，而是在 `AnimationPlayer` 里给 Hitbox 的 `CollisionShape2D.disabled` 打关键帧。这样美术/策划可以在动画库里直接调判定帧，改数值不用改代码。

### 3.2 动作集（玩家的全部操作）

当前已确认键鼠优先，具体键位和瞄准方式尚未确认。下表是**原型建议**，试玩后再定：

| 输入（暂定） | 动作 | 说明 |
|---|---|---|
| WASD | 八向移动 | 移动方向与鼠标瞄准是否分离，待定 |
| 鼠标左键 | 普攻 | 暂按鼠标指向攻击；是否自动锁定目标待试玩 |
| Space | 闪避 | 给敌人清楚的攻击预警，让闪避成为可读的应对方式 |
| Q / R | 局内技能或道具 | 先只放入原型，不预设首版一定有几个技能 |
| E | 交互 | 事件、补给、NPC 或出口；具体交互种类待定 |
| Tab / Esc | 局内信息 / 暂停菜单 | 是否需要传统背包界面，取决于局内物品复杂度 |

**操作原则**：键鼠优先，常用按钮尽量不超过 6 个；不要求复杂组合键或搓招。暂不承诺手柄适配。

### 3.3 资源系统（刻意做了减法）

- **HP**：主要生存资源。局内如何恢复待定，可先由补给点或事件提供有限恢复。
- **体力 Stamina**：**只用于闪避**（25/次，2 秒回满）。不做普攻耗体力——那会让休闲玩家不敢出手。
- **技能**：**纯 CD 制**，不耗蓝。去掉 MP 条 = 少一个 UI、少一套数值、少一堆平衡问题。
- **消耗品**：是否存在、是否跨遭遇保留待定；若加入，按本局物品处理。

### 3.4 命中结算流程

```
玩家按下攻击
  → 状态机进入 ATTACK（不可移动/可小幅位移）
  → AnimationPlayer 播攻击动画
  → 动画帧打开 Hitbox.monitoring（判定开始）
  → Hitbox.area_entered(敌 Hurtbox)
       → Hurtbox 检查：无敌中？已死亡？同阵营？
       → 扣血：Health.take_damage(final_damage)
       → 触发反馈：hitstop + 受击闪白 + 击退 + 伤害数字 + 音效 + 屏震
  → 动画帧关闭 Hitbox
  → 后摇结束 → 回到 IDLE，接受输入缓冲
```

**伤害公式**（先能用，再调）：

```gdscript
func calculate_damage(base: int, attacker_atk: float, defender_def: float,
                      crit_rate: float, crit_mult: float = 1.5) -> int:
    var raw := base * (1.0 + attacker_atk / 20.0)          # 攻击力线性放大
    var reduced := raw * (100.0 / (100.0 + maxf(defender_def, 0.0)))  # 防御递减
    if randf() < crit_rate:
        reduced *= crit_mult
    return maxi(1, int(round(reduced)))                     # 至少 1 点，避免"打不动"
```

> 防御用 `100/(100+DEF)` 而不是 `raw - DEF`：前者永远不会出现"伤害为 0"，也不用担心数值爆炸。

### 3.5 打击感清单（Juice Checklist）

这是"休闲动作游戏好不好玩"的 80%。每一条都要做：

- [ ] **Hitstop（顿帧）**：命中瞬间 `Engine.time_scale = 0.0` 停 0.05–0.08s，重击 0.12s
- [ ] **受击闪白**：敌人 `modulate` 闪白 0.08s，或用 shader 做白化
- [ ] **击退**：受击者沿攻击方向位移 8–16 px，0.15s 衰减
- [ ] **伤害数字**：飘字上浮 + 缩放弹出 + 暴击用金色大字
- [ ] **屏震**：`Camera2D.offset` 随机抖动，强度 2–4 px，衰减 0.12s（重击 6 px）
- [ ] **命中音效**：至少 3 个音高变体随机播，避免"复读机感"
- [ ] **命中粒子**：血/火花贴图喷溅 6–10 颗，0.3s 消失
- [ ] **闪避残影**：翻滚时留下 2–3 个半透明残影
- [ ] **击杀定格**：最后一击 hitstop 加倍 + 轻微慢动作 0.3s
- [ ] **敌人前摇提示**：攻击前 0.3–0.4s 闪红光或举武器，给玩家反应时间

### 3.6 敌人设计：3 + 1 + 1

| 原型 | 行为 | HP | 伤害 | 移速 | 特点/教学目的 |
|---|---|---|---|---|---|
| **史莱姆/野狼（追击型）** | 直线追玩家，接触伤害 | 30 | 6 | 60 px/s | 教"普攻+走位" |
| **强盗弓手（远程型）** | 保持 150px 距离射箭 | 25 | 8 | 50 px/s | 教"必须靠近/闪避" |
| **重甲兵（冲锋型）** | 蓄力 0.6s 后直线冲锋 | 60 | 14 | 55 px/s | 教"用闪避躲开大伤害" |
| **精英：森林巨魔** | 三招轮转（横扫/跳跃砸地/召唤） | 200 | 18 | 50 px/s | 教"看前摇、找后摇" |
| **Boss：堕落骑士** | 二阶段，5 招，半血变招 | 600 | 22 | 55 px/s | 首个目标感关卡 |

**AI 实现只要 3 个状态**（`IDLE → CHASE → ATTACK`，加一个 `HURT`/`DEAD`）：

```gdscript
enum State { IDLE, PATROL, CHASE, WINDUP, ATTACK, HURT, DEAD }
```

- `IDLE`：原地待机，`detection_area` 检测到玩家 → `CHASE`
- `CHASE`：用 `NavigationAgent2D` 追向玩家；进入 `attack_range` → `WINDUP`
- `WINDUP`：播放预警动画（闪红），计时结束 → `ATTACK`（打开 Hitbox）
- `ATTACK` 后摇结束 → 回到 `CHASE`，并进入一个 0.3–0.8s 的"思考停顿"，避免贴脸连击

> **休闲化细节**：给敌人加"攻击冷却随机区间"和"同屏最多 2 个敌人同时攻击"的软限制（用一个 `AttackToken` 单例发令牌），玩家就不会被围殴致死。

### 3.7 难度与无障碍（休闲游戏的必备项）

在设置菜单里考虑提供这些选项；首版先验证核心战斗：

- 受到伤害倍率：100% / 70% / 50% / 25%
- 无敌模式（调试 + 无障碍）
- 关闭屏震 / 降低闪烁（光敏性癫痫友好）
- 可选攻击辅助瞄准/自动朝向（键鼠下是否需要待测试）

---

## 4. 数值与成长

### 4.1 双层成长结构（已确认方向，具体数值待定）

| 层级 | 内容候选 | 是否跨局保留 |
|---|---|---|
| 出发配置 | 出发前自带的基础装备、已拥有遗物及其加成 | **保留，不因死亡或 Boss 胜利而丢失** |
| 局内构筑 | 探险中获得的武器/装备、临时属性、技能变化、消耗品 | **死亡或 Boss 胜利时清空；不带出本局** |
| 局外成长 | Boss 胜利保底获得遗物；死亡按概率获得；重复遗物转碎片购买新遗物或出发加成 | 保留，并影响之后的出发准备 |

这条成长线需要同时满足两点：单局内不断做构筑选择；多次出发后角色或可选策略确实拓展。局外加成优先增加选择和玩法差异，避免数值堆叠让旧内容失去挑战。

### 4.2 遗物与出发准备（当前规则）

- 击败最终 Boss 时保底获得一件遗物；玩家死亡时按概率获得遗物。两种结局下，普通局内物品都不带出。
- 遗物进入持久收藏，并可在出发时提供加成；选择槽位数量、是否消耗、是否允许重复装备待定。
- 遗物效果由设计者固定定义，不生成随机词条；随机性只用于决定掉落哪件遗物。
- 遗物可以改变打法，例如强化闪避后的反击、改变某类攻击或增加事件选项。掉落池按区域、进度或挑战类型筛选，确保每件遗物用途清楚。
- 重复遗物转为**遗物碎片**，在据点购买**新遗物或出发加成**；商店首批商品数量和碎片价格之后按内容量制定。
- Boss 胜利的遗物保底，死亡结算采用概率掉落；死亡掉落率和是否需要连续未掉落保底，在原型中调节。

### 4.3 局内装备与升级（混合成长的原型建议）

- 局内可从精英、事件、补给点或升级选择中获得临时装备与强化。
- 首版可以先做武器变化 + 少量强化词条，不急着实现 24 格背包、多个装备槽、商店价格和复杂稀有度。
- 出发时自带的基础装备不丢；本局后来捡到或选到的普通装备、消耗品和临时资源在死亡或 Boss 胜利后都清空。
- 角色永久等级是否存在、以及出发基础装备如何升级仍待确认；不设计普通装备撤离/带出流程。

### 4.4 经济与风险

旧版“死亡只损失 10% 金币”的方案已取消。当前规则是：**本局新获得的普通物品在两种结局下都会清空；出发配置保留；Boss 胜利保底获得遗物，死亡按概率获得；重复遗物转为碎片**。首版不做本局金币商店；据点碎片商店只出售新遗物和出发加成。

---

## 5. 世界、任务与叙事

### 5.1 据点与室外区域（首版范围待试玩确定）

```
                    [尚未开放的远方]
                           │
   [铁匠/工匠] ─ [中世纪边境据点] ─ [疗伤与整备]
                           │
             [开阔荒野：旧道路、林地、沼泽或丘陵]
                           │
               [地标 / 遭遇 / 事件 / 首领]
```

| 区域 | 作用 | 首版建议内容 |
|---|---|---|
| 边境据点 | 安全整备、遗物选择、碎片商店、承接出发目标、认识 NPC | 少量功能明确的 NPC；商店先只消费遗物碎片 |
| 第一片室外区域 | 验证约 15 分钟探险循环 | 一张手制开阔地图、数条可辨认路线、遭遇/事件/补给点 |
| 后续区域 | 扩充环境主题和敌人组合 | 旧道路、林地、沼泽、丘陵等候选；不是首版交付承诺 |

“开阔”指路线和地形有空间，不等于无边界大地图。建议先制作可控大小的手制区域，在其上随机安排遭遇、事件、奖励与敌人组合；暂不生成整片随机地形。画面要让玩家看清方向与可走区域，避免把野外设计成换皮地牢。

最终 Boss 不由计时器触发。它应位于区域深处的关键路线或地标；玩家走直达路线时可以较早遇到，探索支路和事件则让玩家有机会增强局内构筑，但会花更多时间或承担更多风险。地图路径和 Boss 可达性仍需原型验证。

**待确认**：区域采用固定一张大地图、数个手制区块拼接，还是带分支的场景节点路线。原型先做最省成本的一张手制地图，再看是否需要程序化组合。

### 5.2 每局目标与野外事件

```gdscript
class_name QuestData
extends Resource

@export var id: StringName                 # "secure_old_road"
@export var title: String                  # "打通旧道"
@export var description: String
@export_enum("reach", "clear", "interact", "rescue", "survive") var objective_type: String = "reach"
@export var objective_id: StringName
@export var relic_reward: int = 1
```

每局先给玩家一个明确主目标和可选支路，例如抵达地标、清除威胁、调查异象或救出幸存者。支路提供更多局内强化或更高风险奖励。首个原型只需 **1 个区域、1 个主目标、2–3 类事件**，不先制作 5+5 条长任务链。

### 5.3 叙事与角色关系（方向部分待定）

- **氛围已确认**：中世纪、偏严肃黑暗；“偏向”而非硬性压抑。可以通过据点日常、同伴互助或干涩幽默留出温度。
- **主角身份、世界危机、叙事视角尚未确认**。可考虑“边境不断被某种异变吞没，探险者每次深入都带回情报与遗物”，但先作为提案，不写成设定定案。
- 恋爱、好感度、同伴系统都未确认。先让少量 NPC 在每次出发前后提供观察、传闻和反应；是否发展恋爱线待确认。
- 本版文档没有既定的恋爱生成文案。对话是否手写、规则组合或运行时生成也待确认；原型建议先用可控的手写短文本，避免叙事工具成为首个技术风险。

### 5.4 对话数据（如首个原型需要）

若据点或野外事件需要对话，可先用 JSON 驱动短文本和少量选项：

```json
{
  "blacksmith_glen": {
    "start": {
      "speaker": "铁匠 老格伦",
      "text": "旧路那边又起了黑雾。天黑前别越过石桥。",
      "choices": [
        { "text": "我会去看看。", "next": "accepted", "action": "select_contract:secure_old_road" },
        { "text": "我先准备一下。", "next": "bye" }
      ]
    },
    "accepted": { "speaker": "守路人", "text": "看见路标就回来，别追雾里的声音。", "end": true },
    "bye":      { "speaker": "守路人", "text": "先把装备检查好。", "end": true }
  }
}
```

插件与长篇关系系统都等核心循环成立后再评估。对话示例只用于展示氛围，不代表剧情已定。

---

## 6. 技术框架

### 6.1 项目基线（M0 要做的改造）

当前 `godot-game/project.godot` 还是 3D / Forward Plus 的默认配置，2D 项目需要改这些（**建议在编辑器 UI 里改，避免手写文件出错**）：

| 编辑器搜索关键词 | 设置项 | 值 |
|---|---|---|
| `rendering method` | `rendering/renderer/rendering_method` | `gl_compatibility`（纯 2D 更省电、兼容性好；想保留 Forward Plus 也行） |
| `default texture filter` | `rendering/textures/canvas_textures/default_texture_filter` | `Nearest`（像素风必须） |
| `stretch mode` | `display/window/stretch/mode` | `canvas_items` |
| `stretch aspect` | `display/window/stretch/aspect` | `keep`（当前是 `expand`，会破坏像素对齐） |
| `viewport width/height` | `display/window/size/viewport_width` / `viewport_height` | `480` / `270` |
| `window width override` | `display/window/size/window_width_override` / `window_height_override` | `1440` / `810` |
| `snap 2d transforms` | `rendering/2d/snap/snap_2d_transforms_to_pixel` | `true` |
| `snap 2d vertices` | `rendering/2d/snap/snap_2d_vertices_to_pixel` | `true` |
| `default gravity` | `physics/2d/default_gravity` | `0`（45 度斜视仍用 2D 物理，不需要重力） |
| `physics engine` | `physics/3d/physics_engine` | 3D 引擎设置可留着不管，但 2D 项目里 Jolt 不生效（2D 用 Godot 内置） |

**Autoload（单例）注册顺序**（项目设置 → 全局 → 自动加载）：

```
EventBus      res://scripts/autoload/event_bus.gd
GameState     res://scripts/autoload/game_state.gd
SaveManager   res://scripts/autoload/save_manager.gd
AudioManager  res://scripts/autoload/audio_manager.gd
SceneRouter   res://scripts/autoload/scene_router.gd
```

### 6.2 目录结构（照着建）

```
godot-game/
├─ project.godot
├─ assets/
│  ├─ art/
│  │  ├─ characters/player/     player_sheet.png（idle/run/attack/hurt/death）
│  │  ├─ characters/enemies/    wolf.png / bandit.png / troll.png ...
│  │  ├─ tilesets/              outpost.png / old_road.png / wildlands.png
│  │  ├─ ui/                    hp_bar.png / panel.png / icons/
│  │  ├─ items/icons/           局内武器与装备图标
│  │  ├─ relics/                遗物与出发祝福图标
│  │  └─ fx/                    slash.png / hit_spark.png / dust.png
│  ├─ audio/
│  │  ├─ sfx/                   swing_01.ogg / hit_01.ogg ...
│  │  └─ bgm/                   town.ogg / field.ogg / boss.ogg
│  └─ fonts/                    像素字体（如 Fusion Pixel / Zpix）
├─ data/                        ← 数据驱动，非程序员可编辑
│  ├─ items/*.tres
│  ├─ relics/*.tres
│  ├─ enemies/*.tres
│  ├─ skills/*.tres
│  └─ quests/*.tres
├─ scenes/
│  ├─ main/         Boot.tscn / MainMenu.tscn
│  ├─ world/        Outpost.tscn / Region01.tscn
│  ├─ actors/
│  │  ├─ player/    Player.tscn
│  │  └─ enemies/   Wolf.tscn / Bandit.tscn / Troll.tscn / FallenKnight.tscn
│  ├─ components/   Hitbox.tscn / Hurtbox.tscn / Health.tscn / LootDrop.tscn
│  └─ ui/           HUD.tscn / RelicLoadout.tscn / RunReward.tscn / FragmentShop.tscn / DialogueBox.tscn
├─ scripts/
│  ├─ autoload/     event_bus.gd / game_state.gd / save_manager.gd
│  │                audio_manager.gd / scene_router.gd
│  ├─ actors/       player/player.gd / player/player_stats.gd
│  │                enemies/enemy_base.gd / enemies/enemy_ai.gd
│  ├─ combat/       damage_info.gd / hitbox.gd / hurtbox.gd / health.gd
│  │                combat_util.gd（伤害公式、hitstop）
│  ├─ data/         item_data.gd / relic_data.gd / enemy_data.gd / skill_data.gd / quest_data.gd
│  ├─ systems/      run_state.gd / relic_system.gd / dialogue_system.gd / quest_system.gd
│  │                loot_table.gd / attack_token.gd
│  ├─ world/        interactable.gd / save_point.gd / area_portal.gd
│  └─ ui/           hud.gd / damage_number.gd / run_info.gd / relic_loadout.gd
├─ resources/       theme.tres / palette.tres
└─ docs/            本设计文档
```

### 6.3 核心场景树

**Player.tscn**
```
Player (CharacterBody2D)              [layer: Player]  [mask: World]
├─ Sprite (Sprite2D)                  hframes=4, 用 AnimationPlayer 驱动 frame
├─ AnimationPlayer                    idle_*/run_*/attack_1..3/roll/hurt/death
├─ CollisionShape2D                   CapsuleShape2D，脚部小圆更好走位
├─ Hurtbox (Area2D)                   [layer: PlayerHurtbox] monitoring=false, monitorable=true
│  └─ CollisionShape2D
├─ Health (Node, health.gd)
├─ Stats (Node, player_stats.gd)
├─ HitboxPivot (Node2D)               ← 随朝向旋转，攻击时打开 Hitbox
│  └─ Hitbox (Area2D)                 [layer: PlayerHitbox] [mask: EnemyHurtbox]
│     └─ CollisionShape2D             disabled 由动画帧控制
├─ InteractArea (Area2D)              [mask: Interactable]
└─ Camera2D                           position_smoothing_enabled=true, limit 跟随地图边界
```

**Enemy 基类场景**（`Wolf.tscn` 等继承同一个 `enemy_base.tscn`）
```
Enemy (CharacterBody2D)               [layer: Enemy] [mask: World]
├─ Sprite (Sprite2D)
├─ AnimationPlayer
├─ CollisionShape2D
├─ Hurtbox (Area2D)                   [layer: EnemyHurtbox]
├─ Hitbox (Area2D)                    [layer: EnemyHitbox] [mask: PlayerHurtbox]
├─ Health
├─ DetectionArea (Area2D)             发现玩家
├─ NavigationAgent2D                  寻路
└─ EnemyData (@export, .tres 注入数值)
```

**World 场景（Town.tscn 等）**
```
World (Node2D)
├─ Ground (TileMapLayer)              z_index=-10
├─ Walls (TileMapLayer)               + StaticBody2D 碰撞 / 或用 TileSet 物理层
├─ NavigationRegion2D                 供敌人寻路
├─ Entities (Node2D)                  玩家、NPC、敌人、宝箱运行时挂到这里
├─ Interactables (Node2D)
└─ Bounds (参考 Marker2D)             相机边界
```

**HUD.tscn（`CanvasLayer`，`process_mode = ALWAYS` 以便暂停时也能响应）**
```
HUD (CanvasLayer)
├─ HealthBar / StaminaBar / SkillIcons(带 CD 遮罩)
├─ ObjectiveProgress / RunResourceDisplay（如原型需要）
├─ DamageNumbers (Node2D 世界坐标飘字池)
└─ PauseMenu / RunInfo / DialogueBox（初始 visible=false）
```

### 6.4 战斗核心代码骨架

**`scripts/combat/damage_info.gd`**
```gdscript
class_name DamageInfo
extends RefCounted

var amount: int = 0
var source: Node2D = null            # 攻击者
var is_crit: bool = false
var knockback: Vector2 = Vector2.ZERO
var hitstop: float = 0.06
```

**`scripts/combat/health.gd`**
```gdscript
class_name Health
extends Node

signal changed(current: int, maximum: int)
signal damaged(info: DamageInfo)
signal died

@export var max_hp: int = 100
var current: int = 0
var is_dead: bool = false

func _ready() -> void:
    current = max_hp

func take_damage(info: DamageInfo) -> void:
    if is_dead:
        return
    current = maxi(current - info.amount, 0)
    damaged.emit(info)
    changed.emit(current, max_hp)
    if current == 0:
        is_dead = true
        died.emit()

func heal(value: int) -> void:
    if is_dead:
        return
    current = mini(current + value, max_hp)
    changed.emit(current, max_hp)
```

**`scripts/combat/hitbox.gd`**
```gdscript
class_name Hitbox
extends Area2D

signal hit_landed(info: DamageInfo)

@export var base_damage: int = 8
@export var attack_power: float = 10.0
@export var knockback_force: float = 120.0
@export var hitstop: float = 0.06
@export var crit_rate: float = 0.05
@export var owner_actor: Node2D          # 攻击者，用来排除自伤

var _already_hit: Array[Hurtbox] = []

func _ready() -> void:
    monitoring = true
    monitorable = false                  # 判定框不需要被别人检测
    area_entered.connect(_on_area_entered)

## 由 AnimationPlayer 的「调用方法」轨道调用
func begin() -> void:
    _already_hit.clear()
    set_deferred("monitoring", true)

func end() -> void:
    set_deferred("monitoring", false)

func _on_area_entered(area: Area2D) -> void:
    var hurtbox := area as Hurtbox
    if hurtbox == null or hurtbox in _already_hit:
        return
    if hurtbox.owner_actor == owner_actor:   # 不打自己
        return
    _already_hit.append(hurtbox)

    var defender := hurtbox.get_defense()
    var info := DamageInfo.new()
    info.source = owner_actor
    info.is_crit = randf() < crit_rate
    info.amount = CombatUtil.calculate_damage(
        base_damage, attack_power, defender, 1.0 if info.is_crit else 0.0)
    info.knockback = (hurtbox.global_position - global_position).normalized() * knockback_force
    info.hitstop = hitstop
    hit_landed.emit(info)
    hurtbox.take_hit(info)
```

**`scripts/combat/hurtbox.gd`**
```gdscript
class_name Hurtbox
extends Area2D

@export var owner_actor: Node2D
@export var health: Health
@export var defense: float = 0.0
@export var invincible: bool = false

func _ready() -> void:
    monitoring = false                   # 只被检测，不主动检测 —— 省性能
    monitorable = true

func get_defense() -> float:
    return defense

func take_hit(info: DamageInfo) -> void:
    if invincible or health == null or health.is_dead:
        return
    health.take_damage(info)

## 闪避无敌帧：同时关掉 monitorable，敌人攻击会直接穿过
func set_invincible(value: bool) -> void:
    invincible = value
    set_deferred("monitorable", not value)
```

**`scripts/combat/combat_util.gd`**（可做成静态类或 Autoload）
```gdscript
class_name CombatUtil

static func calculate_damage(base: int, atk: float, def: float, crit_bonus: float = 0.0) -> int:
    var raw := base * (1.0 + atk / 20.0)
    var reduced := raw * (100.0 / (100.0 + maxf(def, 0.0)))
    if crit_bonus > 0.0:
        reduced *= 1.5
    return maxi(1, int(round(reduced)))

static func hitstop(tree: SceneTree, duration: float) -> void:
    Engine.time_scale = 0.0
    # 第 4 个参数 ignore_time_scale=true，否则 time_scale=0 时计时器永远不走
    await tree.create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0

static func shake(camera: Camera2D, strength: float, duration: float = 0.12) -> void:
    var t := 0.0
    while t < duration:
        camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength
        t += camera.get_process_delta_time()
        await camera.get_tree().process_frame
    camera.offset = Vector2.ZERO
```

### 6.5 玩家状态机 + 输入缓冲

```gdscript
class_name Player
extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, ROLL, HURT, DEAD }

const SPEED := 90.0
const ROLL_SPEED := 240.0
const ROLL_STAMINA := 25.0
const INPUT_BUFFER := 0.15      # 输入缓冲窗口，休闲手感的关键

@onready var sprite: Sprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $HitboxPivot/Hitbox
@onready var hitbox_pivot: Node2D = $HitboxPivot

var state: State = State.IDLE
var facing := Vector2.DOWN
var stamina := 100.0
var _combo_index := 0
var _combo_timer := 0.0
var _buffered := &""
var _buffer_timer := 0.0
var _roll_dir := Vector2.ZERO

func _ready() -> void:
    hitbox.owner_actor = self
    hurtbox.owner_actor = self
    hurtbox.health = health
    health.died.connect(_on_died)
    anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
    _tick_timers(delta)
    match state:
        State.IDLE, State.RUN: _process_move(delta)
        State.ROLL:            _process_roll(delta)
        State.ATTACK:          velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
        State.HURT, State.DEAD: velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)
    move_and_slide()

func _tick_timers(delta: float) -> void:
    stamina = minf(stamina + 45.0 * delta, 100.0)
    _combo_timer = maxf(_combo_timer - delta, 0.0)
    if _combo_timer == 0.0:
        _combo_index = 0
    _buffer_timer = maxf(_buffer_timer - delta, 0.0)
    if _buffer_timer == 0.0:
        _buffered = &""

func _unhandled_input(event: InputEvent) -> void:
    # 输入缓冲：不在可行动状态也记下按键，状态允许时立刻执行
    if event.is_action_pressed("attack"):
        _buffer(&"attack")
    elif event.is_action_pressed("roll"):
        _buffer(&"roll")
    elif event.is_action_pressed("skill_a"):
        _buffer(&"skill_a")

func _buffer(action: StringName) -> void:
    _buffered = action
    _buffer_timer = INPUT_BUFFER

func _process_move(delta: float) -> void:
    var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = dir * SPEED
    if dir != Vector2.ZERO:
        facing = dir
        _update_facing_anim()
        if state != State.RUN:
            state = State.RUN
            anim.play("run")
    else:
        if state != State.IDLE:
            state = State.IDLE
            anim.play("idle")
    hitbox_pivot.rotation = facing.angle()

    if _buffered == &"roll" and stamina >= ROLL_STAMINA:
        _start_roll()
    elif _buffered == &"attack":
        _start_attack()

func _start_attack() -> void:
    state = State.ATTACK
    _buffered = &""
    _combo_index = clampi(_combo_index + 1, 1, 3)
    _combo_timer = 0.45
    anim.play("attack_%d" % _combo_index)

func _start_roll() -> void:
    state = State.ROLL
    _buffered = &""
    stamina -= ROLL_STAMINA
    _roll_dir = facing.normalized()
    hurtbox.set_invincible(true)
    anim.play("roll")

func _process_roll(delta: float) -> void:
    velocity = _roll_dir * ROLL_SPEED
    # 无敌帧与位移在动画结束后由 _on_anim_finished 收尾

func _on_anim_finished(anim_name: StringName) -> void:
    match anim_name:
        "roll":
            hurtbox.set_invincible(false)
            state = State.IDLE
        _:
            if anim_name.begins_with("attack"):
                state = State.IDLE
                if _buffered == &"attack":     # 连段衔接
                    _start_attack()

func _on_died() -> void:
    state = State.DEAD
    anim.play("death")
    EventBus.player_died.emit()
```

**动画里怎么打开判定框**：在 `attack_1` 动画中加一条 **「调用方法」轨道**，在判定起点调用 `Hitbox.begin()`，终点调用 `Hitbox.end()`。判定框位置由 `HitboxPivot` 的旋转决定，动画里还可以额外 K 位移让判定范围前伸。

### 6.6 数据驱动与存档

**`scripts/autoload/event_bus.gd`**（全局信号，避免节点间硬引用）
```gdscript
extends Node
# 使用方式：EventBus.relics_changed.emit(total)

signal player_died
signal player_hp_changed(current: int, maximum: int)
signal run_started(run_id: int)
signal run_ended(result: StringName)
signal relics_changed(total: int)
signal relic_fragments_changed(total: int)
signal relic_loadout_changed(relic_ids: Array[StringName])
signal boon_chosen(boon_id: StringName)
signal item_picked(item: ItemData)
signal objective_updated(objective_id: StringName, progress: int)
signal region_entered(region_id: StringName)
signal damage_dealt(info: DamageInfo)
```

**`scripts/autoload/save_manager.gd`**（原子写入 + 版本号）

存档至少要保存局外遗物、解锁项和设置。**中途退出时是否保留当前单局**尚未决定；定下规则前，不要把临时背包误存成永久进度。原型可先在回到据点或单局结算时保存局外数据。

```gdscript
extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://save_0.json"
const TMP_PATH := "user://save_0.json.tmp"

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
    var payload := {
        "version": SAVE_VERSION,
        "meta_progression": GameState.meta_progression_to_dict(),
        "unlocks": GameState.unlocks_to_dict(),
        "settings": GameState.settings_to_dict(),
        # "active_run": RunState.to_dict()  # 是否可续局待定；默认不保存临时物品
    }
    var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
    if f == null:
        push_error("存档失败：%s" % error_string(FileAccess.get_open_error()))
        return
    f.store_string(JSON.stringify(payload, "\t"))
    f.close()
    DirAccess.rename_absolute(ProjectSettings.globalize_path(TMP_PATH),
                              ProjectSettings.globalize_path(SAVE_PATH))

func load_game() -> Dictionary:
    if not has_save():
        return {}
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("存档损坏")
        return {}
    var data: Dictionary = parsed
    var version: int = data.get("version", 1)
    if version < SAVE_VERSION:
        data = _migrate(data, version)
    return data

func _migrate(data: Dictionary, from_version: int) -> Dictionary:
    # 逐版本升级局外进度与设置结构；单局状态格式需在续局规则确认后加入。
    data["version"] = SAVE_VERSION
    return data
```

### 6.7 场景切换

```gdscript
# scripts/autoload/scene_router.gd
extends Node

signal area_loaded(area_id: StringName)

var current_area: StringName = &""
var _spawn_point: StringName = &""

func goto_area(area_id: StringName, spawn_point: StringName = &"default") -> void:
    current_area = area_id
    _spawn_point = spawn_point
    var path := "res://scenes/world/%s.tscn" % _to_scene_name(area_id)
    # 用 call_deferred 避免在物理回调里直接换场景
    get_tree().call_deferred("change_scene_to_file", path)

func get_spawn_point() -> StringName:
    return _spawn_point

func _to_scene_name(area_id: StringName) -> String:
    return String(area_id).to_pascal_case()
```

> 换场景是异步的（`change_scene_to_file` 在帧末执行），所以新场景的 `_ready()` 里用 `SceneRouter.get_spawn_point()` 决定玩家出现在哪个 `Marker2D`。

### 6.8 性能与工程习惯

- **别把所有东西写在 `_process` 里**：不动的敌人 `set_physics_process(false)`；远离玩家的敌人用 `VisibleOnScreenNotifier2D` 休眠。
- **Hurtbox 关闭 `monitoring`**：100 个 Hurtbox 主动检测是纯浪费。
- **池化飘字与粒子**：伤害数字会频繁生成/销毁，用对象池（预建 30 个，循环复用）。
- **`set_deferred` 修改物理属性**：在 `area_entered` 回调里直接改 `monitoring` / `disabled` 会报错。
- **导航**：`NavigationRegion2D` 烘焙后，敌人用 `NavigationAgent2D.get_next_path_position()`；地图改了记得重新烘焙。
- **碰撞体与绘制顺序**：45 度斜视可按角色脚底位置参与碰撞和 Y 轴绘制排序，让前后遮挡自然。
- **版本管理**：每个里程碑一个 commit；美术/音频资源大了再上 Git LFS（`.gitignore` 已忽略 `.godot/`，很好）。

---

## 7. 实现流程（垂直切片）

> 原则：**每个里程碑结束时游戏都能运行、能玩**。绝不做"写完 5 个系统再一起调试"。

| 里程碑 | 目标 | 交付物 | 验收标准 |
|---|---|---|---|
| **M0 项目基线** | 项目能运行 | 设置 2D 项目、建立最小目录、主场景和存档骨架 | 能启动到测试场景 |
| **M1 室外移动** | 先验证视角和空间感 | 玩家移动、相机、碰撞、一张简易开阔野外地图 | 能看懂路线并在地图中移动 |
| **M2 轻动作战斗** | 验证普通战斗是否舒服 | 普攻、闪避、受击、一个训练目标和一种敌人 | 键鼠输入清楚，敌人攻击可读，躲招有效 |
| **M3 遭遇变化** | 建立战斗节奏 | 2–3 种敌人行为、预警、精英遭遇、掉落 | 玩家能选择接战/绕行，遭遇不会只换数值 |
| **M4 单局流程** | 组成探险 | 据点出发、路线选择、事件/补给点、最终 Boss、死亡结算 | 死亡或击败 Boss 都能结束一局；平均时长接近 15 分钟，遇 Boss 时间由路线与速度决定 |
| **M5 双层成长** | 验证重开动力 | 出发配置、局内临时强化、Boss 保底遗物、死亡概率掉落、碎片商店 | 重复遗物转碎片；碎片购买新遗物或出发加成 |
| **M6 氛围与内容** | 做出完整示例 | 一处据点、一个手制室外区域、简短目标/事件、音画反馈 | 试玩者能复述本局目标、风险与成长结果 |
| **M7 垂直切片包装** | 让别人可以试玩 | 主菜单、暂停、必要设置、存档、声音和结算界面 | 玩家可独立完成多局并理解局外成长 |
| **后续扩充** | 根据试玩证据加内容 | 更多室外区域、敌人、遗物、事件和关系内容 | 优先扩充已证明好玩的系统 |

**工期暂不估算**：开发者熟练度、每周投入和最终平台还未确认。原方案中的“两周/14 天”属于未经验证的估计，不作为承诺；先按里程碑拆解，再根据第一张地图和战斗原型重新估时。

### 7.1 垂直切片（Vertical Slice）定义

首个垂直切片应包含：

> 据点选择遗物与基础装备 → 进入一片开阔室外区域 → 自选探索路线、应对遭遇并拿到局内强化 → 按路线和速度遇到最终 Boss，或在途中死亡 → 本局新物品清空、按结局概率结算遗物 → 重复遗物换成碎片，在据点购买成长内容并准备下一次出发。

这个切片验证：**键鼠轻动作、45 度 2D 斜视室外探索、约 15 分钟单局、Boss/死亡双结局、遗物驱动的局外成长** 是否能连成一个有动力重开的循环。

## 8. 首个垂直切片日程

以下按依赖关系排序，不绑定日历天数。完成每一阶段都应能运行和试玩：

| 阶段 | 任务 | 可验证结果 |
|---|---|---|
| 1 | 2D 项目基线、像素显示、启动场景 | 项目能启动 |
| 2 | 玩家移动、相机、开阔地形碰撞 | 角色能在室外空间行动 |
| 3 | 普攻、闪避、命中反馈 | 战斗输入明确、躲招可行 |
| 4 | 敌人预警与基础遭遇 | 玩家能读懂并处理敌人行为 |
| 5 | 一张室外区域、分支路线、事件与补给 | 探索路线影响战力和遇到 Boss 的时机 |
| 6 | 最终 Boss、死亡与胜利结算 | 两种结束条件都能正确结束本局并清空局内新物品 |
| 7 | 遗物结算、重复转碎片、碎片商店和存档 | Boss 胜利保底；死亡概率掉落；碎片购买新遗物或出发加成 |
| 8 | 音画包装、菜单、外部试玩与迭代 | 新玩家能独立完成并理解循环 |

---

## 9. 美术与音频资源方案

### 9.1 美术原型基线（验证后再定）

下列像素尺寸是现有方案提供的起始值；目前只确定像素风，先用这些值做灰盒或首张地图，看到实际画面后再锁定规范。

| 项目 | 规范 |
|---|---|
| tile 尺寸 | **16×16** |
| 角色尺寸 | 16×24（比 tile 高一点，视觉更立体） |
| 内部分辨率 | 480×270（30×16.875 tile） |
| 缩放 | 整数倍，窗口 1440×810（3×） |
| 朝向 | 原型先试 4 方向斜视角色；是否需要 8 方向仍待美术与瞄准原型验证 |
| 色彩 | 暂定低饱和、偏冷的中世纪荒野色调；用少量暖光、火把和营地灯光提供安全感 |
| 动画帧率 | 8–12 FPS（像素风不要 60 FPS） |
| 文件格式 | PNG（无损），不要 JPG |

### 9.2 素材来源（免费/可商用，注意授权）

| 来源 | 内容 | 授权 |
|---|---|---|
| **Kenney.nl** | 大量 2D 素材、UI、音效 | CC0，最省心 |
| **itch.io**（搜 "LPC"、"Tiny Swords"、"Sprout Lands"） | 中世纪角色/场景 | 多为 CC-BY 或免费商用 |
| **OpenGameArt.org** | LPC（Liberated Pixel Cup）全套中世纪素材 | CC-BY-SA 3.0，注意署名与传染性 |
| **Freesound.org** | 打击音效 | 逐个确认 CC0/CC-BY |
| **Pixabay / Mixkit** | BGM | 免费商用 |
| **Aseprite / LibreSprite** | 像素绘画工具 | 自行绘制（推荐：先统一风格，比混用素材好看） |

> ⚠️ **一定要建 `docs/CREDITS.md`**，逐个记录素材来源与授权。上架时这是硬性要求，事后补极其痛苦。

### 9.3 音频设计重点

- **打击音效是打击感的 50%**：准备 3 个音高变体随机播放，避免疲劳。
- **音效要"提前 1 帧"**：在判定帧而不是命中反馈帧播放挥砍音（`AudioStreamPlayer` 用 `play()` 而非 `play(from_position)`）。
- **音频总线**：`Master → BGM / SFX / UI`，设置菜单挂 3 个滑条。
- **BGM 切换用淡入淡出**：给 `AudioStreamPlayer` 写一个 0.5s 补间，别硬切。

---

## 10. 风险与常见坑

| 风险 | 症状 | 对策 |
|---|---|---|
| **范围蔓延** | "再加个钓鱼系统吧" | 把第 1.3 节的反目标贴在显示器上；新想法一律进 `docs/IDEAS_BACKLOG.md`，不进当前里程碑 |
| **手感调不出来** | 打怪像敲空气 | M2–M4 之前禁止做任何其他系统；先把手感做到"自己愿意反复砍木桩 5 分钟" |
| **美术卡死** | 代码写完了没素材 | 用色块 + 免费素材先跑通；**永远不要让美术阻塞程序** |
| **过度设计 FSM** | 花 3 天写行为树 | 3 状态够用；等第 6 种敌人出现再重构 |
| **存档格式反复变** | 老存档读不了 | `SAVE_VERSION` + `_migrate()` 从第一天就写 |
| **数值平衡黑洞** | 无限调数值 | 先用占位数值完成战斗和一局循环；每轮试玩只调最影响体验的参数 |
| **`time_scale = 0` 导致卡死** | 顿帧后游戏不动了 | `create_timer` 第 4 参数必须 `ignore_time_scale = true` |
| **物理回调里改属性报错** | "Can't change this state while flushing queries" | 一律用 `set_deferred()` |
| **场景切换崩溃** | 在信号回调里 `change_scene` | 用 `get_tree().call_deferred("change_scene_to_file", path)` |
| **像素抖动** | 移动时贴图抖 | 打开 snap 设置；相机位置取整（`round()`）；避免非整数缩放 |

---

## 11. 后续扩展路线

核心 Roguelite 循环已经属于首版目标。以下是垂直切片验证之后再考虑的扩展，不是当前承诺：

1. **增加室外区域与路线变体** —— 先保持每片区域手制，再增加可组合的遭遇和事件
2. **更多敌人、精英与户外首领战** —— 让不同区域形成各自的战斗节奏
3. **遗物和局内构筑扩展** —— 增加改变打法的选择，而不是只叠数值
4. **昼夜、天气与环境威胁** —— 让荒野氛围和路线选择产生变化
5. **NPC 关系、羁绊或恋爱线** —— 尚待决定；首版不预设分支规模
6. **多武器类型与技能组合** —— 等基础战斗与键鼠瞄准方式定型后再做
7. **平台适配与发行准备** —— 目标平台和发行计划尚未确认

---

## 附录 A. 战斗原型占位数值（待试玩）

以下只作为最初灰盒测试的参考，不能视为成长曲线或经济系统已定。旧版等级、金币价格和永久装备曲线已不适用于当前的局内/局外双层成长方向。

**玩家基础值候选**：HP 100、攻击 10、防御 5、移动速度 90 px/s。先用这些值测试一场普通遭遇，再根据约 15 分钟单局的受伤频率和战斗时长调整。

**局内武器候选**

| 名称 | 定位 | 获取方式（候选） |
|---|---|---|
| 生锈短剑 | 基础近战 | 作为出发配置携带；具体基础装备待定 |
| 铁剑 | 稳定伤害提升 | 遭遇或补给事件 |
| 精钢长剑 | 攻速/范围取舍型 | 精英遭遇或高风险路线 |
| 骑士剑 | 强力局内装备 | 区域目标或首领奖励 |

**敌人灰盒候选**

| 原型 | HP | 伤害 | 移速 | 攻击距离 | 教学目的 |
|---|---:|---:|---:|---:|---|
| 追击型（野狼） | 30 | 6 | 60 | 22 | 普攻、走位和脱离 |
| 远程型（弓手） | 25 | 8 | 50 | 150 | 借地形接近、读射击预警 |
| 冲锋型（重甲兵） | 60 | 14 | 55 | 26 | 识别蓄力并闪避 |
| 精英（森林巨魔） | 200 | 18 | 50 | 34 | 观察大范围攻击和后摇 |
| 户外首领（堕落骑士，暂名） | 600 | 22 | 55 | 40 | 验证单局高潮与多招预警 |

---

## 附录 B. 键鼠输入映射（原型建议）

首版优先支持键鼠。具体键位尚未确认；可先按下表做原型，测试鼠标瞄准与近战方向后再定：

| 动作名 | 键鼠（原型建议） | 类型 |
|---|---|---|
| `move_up` | W / ↑ | 轴 |
| `move_down` | S / ↓ | 轴 |
| `move_left` | A / ← | 轴 |
| `move_right` | D / → | 轴 |
| `attack` | 鼠标左键（备选 J） | 按钮 |
| `dodge` | Space | 按钮 |
| `skill_1` | Q（暂定） | 按钮 |
| `interact` | E | 按钮 |
| `run_info` | Tab（暂定） | 按钮 |
| `pause` | Esc | 按钮 |

> 移动用 `Input.get_vector(...)` 而不是四个 `is_action_pressed`，可自动处理斜向归一化。鼠标是否负责瞄准、是否需要锁定目标，应在 M2 原型中确认。

---

## 附录 C. 碰撞层规划表

**层（Layer = 我在哪一层）**

| 编号 | 名称 | 使用者 |
|---|---|---|
| 1 | World | 墙壁、树木、水、边界 |
| 2 | Player | 玩家本体 |
| 3 | Enemy | 敌人本体 |
| 4 | PlayerHitbox | 玩家的攻击判定 |
| 5 | EnemyHitbox | 敌人的攻击判定 |
| 6 | PlayerHurtbox | 玩家的受击判定 |
| 7 | EnemyHurtbox | 敌人的受击判定 |
| 8 | Interactable | NPC、野外事件、补给点、出口 |
| 9 | Pickup | 掉落物 |
| 10 | Projectile | 弓箭、法术 |

**掩码（Mask = 我检测哪些层）**

> ⚠️ 掩码在 Godot 里是**位掩码（bitmask）**：要检测"层 7"，勾选的是第 7 个复选框，其数值是 `2^(7-1) = 64`，**不是 7**。下表的 Mask 列一律写**层名**，在检视面板里勾对应的复选框即可，别去手填数字。

| 节点 | Layer（我在哪层） | Mask（我检测哪些层） | 说明 |
|---|---|---|---|
| Player (CharacterBody2D) | Player | World | **不撞敌人**——避免 45 度斜视下贴身单位卡位和抖动 |
| Enemy (CharacterBody2D) | Enemy | World | 同上 |
| PlayerHitbox (Area2D) | PlayerHitbox | EnemyHurtbox | 只找敌人受击框 |
| EnemyHitbox (Area2D) | EnemyHitbox | PlayerHurtbox | 只找玩家受击框 |
| PlayerHurtbox (Area2D) | PlayerHurtbox | （空） | `monitoring=false, monitorable=true` |
| EnemyHurtbox (Area2D) | EnemyHurtbox | （空） | 同上 |
| Player.InteractArea | （空） | Interactable | 只检测可交互物 |
| Pickup | Pickup | Player | 检测玩家（或用磁吸范围） |

> **敌人之间不互相碰撞**：用 `PhysicsServer2D` 的软推挤或干脆允许重叠。一群怪糊在一起虽然不"物理"，但对休闲游戏的手感反而更宽容。

---

## 附录 D. 事件总线信号清单

```gdscript
# EventBus（Autoload）
signal player_died
signal player_hp_changed(current: int, maximum: int)
signal player_stamina_changed(current: float, maximum: float)
signal run_started(run_id: int)
signal run_ended(result: StringName)
signal relics_changed(total: int)
signal relic_fragments_changed(total: int)
signal relic_loadout_changed(relic_ids: Array[StringName])
signal boon_chosen(boon_id: StringName)
signal damage_dealt(info: DamageInfo)
signal enemy_killed(enemy_id: StringName)
signal item_picked(item: ItemData)
signal run_objective_updated(objective_id: StringName, progress: int)
signal dialogue_started(npc_id: StringName)
signal dialogue_finished(npc_id: StringName)
signal region_entered(region_id: StringName)
signal game_saved
signal game_loaded
signal settings_changed
```

**使用原则**：
- 跨系统通信（HUD、任务、音频）**只走 EventBus**，不让 HUD 去 `get_node("../../Player")`。
- 同一场景内的父子关系（Player ↔ Hurtbox）**用直接引用**，不要绕信号总线。
- 信号命名统一用**过去式**（`damaged`、`died`、`changed`），一眼能看出是"已经发生"。

---

## 附录 E. Godot 4.7 项目设置改动清单

M0 阶段逐项确认（在**项目 → 项目设置**的搜索框里直接搜左边的关键词）：

- [ ] `rendering method` → `gl_compatibility`（2D 项目推荐，也可保留 `forward_plus`）
- [ ] `default texture filter` → `Nearest`
- [ ] `stretch mode` → `canvas_items`
- [ ] `stretch aspect` → `keep`
- [ ] `viewport_width` = `480`，`viewport_height` = `270`
- [ ] `window_width_override` = `1440`，`window_height_override` = `810`
- [ ] `snap_2d_transforms_to_pixel` = `true`
- [ ] `snap_2d_vertices_to_pixel` = `true`
- [ ] `physics/2d/default_gravity` = `0`
- [ ] **键鼠输入映射**：按附录 B 的原型建议建立，测试后定稿
- [ ] **2D 物理层命名**：按附录 C 填好 `layer_names/2d_physics/layer_1..10`
- [ ] **自动加载**：EventBus / GameState / SaveManager / AudioManager / SceneRouter
- [ ] **主场景**：`res://scenes/main/Boot.tscn`

**运行方式**（编辑器未加入 PATH，用桌面上的可执行文件）：

```powershell
# 打开编辑器
& "C:\Users\ljh\Desktop\Godot_v4.7.2-stable_win64.exe" --path "C:\Users\ljh\Desktop\game\godot-game" -e

# 直接运行（调试输出打到控制台）
& "C:\Users\ljh\Desktop\Godot_v4.7.2-stable_win64.exe" --path "C:\Users\ljh\Desktop\game\godot-game"
```

---

## 下一步

当前核心方向已足够进入原型。建议按以下顺序验证：

1. 用 45 度 2D 斜视搭一张开阔室外灰盒地图，验证键鼠移动、瞄准、碰撞和 Y 轴绘制顺序。
2. 做出基础敌人、清楚的攻击预警和轻动作战斗，调到“看提示能躲、操作不繁琐”。
3. 加入可选路线与局内强化，让探索速度影响最终 Boss 的到达时机，目标平均单局约 15 分钟。
4. 实现两种结束结算：Boss 胜利保底掉落遗物；死亡按概率掉落；重复遗物转换为碎片。
5. 在据点加入碎片商店，首批只提供新遗物和出发加成；完成多局试玩后再扩充区域、叙事与内容量。

死亡掉落率、商店具体货品和遗物配置数量按原型体验调节；平台、开发工期、美术来源、主角设定与 NPC 关系线留待后续制作规划，不阻塞核心循环原型。
