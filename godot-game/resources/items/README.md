# 道具资源配置

道具共用 `scenes/items/item_pickup.tscn`。场景负责图标显示和 Area2D 拾取，`ItemConfig` 资源负责外观、掉落权重和效果。宝箱共用 `scenes/items/treasure_chest.tscn`，从 `loot_pool` 中按权重抽取可使用的资源。

## 新增道具

1. 复制一份本目录的 `.tres`，设置唯一的 `item_id`、名称、描述和 `icon_texture`。
2. 设置 `effect_type` 与 `strength`。施法频率、移动速度使用倍率，如 `1.25` 表示提高 25%；法术威力、治疗使用固定数值。
3. 设置 `duration_mode`：`INSTANT` 立即生效，`TIMED` 持续 `duration` 秒，`UNTIL_RUN_END` 持续到本局结束。治疗使用 `INSTANT`。
4. 设置 `max_stacks` 和 `drop_weight`。限时效果在达到层数上限后再次拾取会刷新时间；本局效果在达到上限后不会再被随机宝箱抽中。权重为 `0` 时不参与随机掉落，但仍可作为宝箱的 `fixed_loot`。
5. 把资源加入宝箱实例的 `loot_pool`，或把通用拾取场景放到地图中并指定其 `item_config`。

当前控制器支持施法频率、移动速度、法术威力和治疗四类效果。新增同类道具只需新建资源；新增效果类别需要在 `scripts/items/item_effect_controller.gd` 中添加对应的计算逻辑。

玩家场景中的 `ItemEffects` 节点可设置最高移速倍率和最短施法间隔。资源在运行中作为只读配置使用，剩余时间和叠加层数只保存在该节点内；重新开始一局时自然清空。
