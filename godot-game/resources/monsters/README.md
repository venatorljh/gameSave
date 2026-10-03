# 资源驱动怪物

所有怪物共用 `res://scenes/monsters/monster.tscn` 和 `res://scripts/monsters/monster_actor.gd`。每种怪物只创建一份 `MonsterConfig`（`.tres`），在场景实例的 `monster_config` 属性中指定；生命值、攻击方式、感知范围、速度、碰撞尺寸、贴图和动画行都从资源读取。运行中的血量与状态只保存在怪物实例，不写回资源。

## 当前配置

| 资源 | 动画切法 | 攻击 |
| --- | --- | --- |
| `skeleton.tres` | 原图每格 32×32、每排 10 帧。第 1～2 排接成巡逻，第 3 排追赶，第 4 排攻击，第 5 排死亡。 | 停步挥臂；短暂前摇后，前方圆形判定造成一次伤害。 |
| `eyeball.tres` | 原图每格 32×32、每排 8 帧。第 1 排巡逻，第 2 排追赶，第 3 排攻击；独立的 4 帧炸裂图用于死亡。 | 锁定玩家方向、短暂前摇后直线冲撞；碰到障碍即结束冲撞。 |

`DetectionArea` 只检测物理层 2（玩家）；怪物本体在层 3，能被现有魔法弹和斩击的命中逻辑调用 `take_damage`。`AttackArea` 也只检测玩家，单次攻击对同一个目标最多造成一次伤害。图片会按目标的左右位置水平翻转；`art_faces_right` 表示原图是否朝右。怪物死亡时关闭碰撞，播放死亡动画后移除。

## 新增怪物

1. 复制一份 `.tres`，填写 `monster_id`、生命、速度、锁敌半径和攻击参数。
2. 设置主 spritesheet 的单格尺寸、每排行数及 `patrol_rows` / `chase_rows` / `attack_rows`。行号从 0 开始；多行会依次接成一段动画。
3. 指定 `death_rows`。若死亡图是单独文件，同时填写 `death_sheet`、`death_frame_size`、`death_frames_per_row` 和 `death_sprite_scale`。
4. 在地图里实例化共用场景，只覆盖 `monster_config` 属性。无需为每种怪物复制场景或脚本。

`ARM_SWING` 用朝玩家方向偏移的短距离命中区域；`CHARGE` 在攻击有效时间内按锁定方向冲刺。巡逻会在出生点附近随机选点，发现玩家后追赶，玩家离开感知区或怪物超过最大追赶距离后返回巡逻。

眼球炸裂图由内置 imagegen 根据原始眼球图生成：四帧依次为眼球鼓起、开裂、炸开、碎片散落；游戏引用的文件是 `res://monsters/eyeball_death_spritesheet.png`。
