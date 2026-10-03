# 怪物逐帧图素材

这里只保存图片、原始压缩包与来源说明；怪物场景、AI 和动画资源尚未创建。所有 PNG 均为带透明通道的原始 spritesheet，可在 Godot 中按格切成连续帧。

当前地图使用 Calciumtrice 的户外瓦片：低分辨率、清晰像素边缘、偏暗的草地/泥土/岩石配色。优先试用同作者系列；需要敌人随移动方向改变外观时，优先试用 `puny_characters`。

| 目录 | 内容与动作 | 方向及切图提示 | 来源和许可 |
| --- | --- | --- | --- |
| `puny_characters/` | 5 种兽人外观和 1 张史莱姆图。兽人包含待机、走路、剑/弓/法杖/投掷攻击、受伤、死亡。 | 兽人图每格 32×32，图片为 24 列 × 8 行；角色实际约占 16×16。兽人有 8 方向。史莱姆为单行图，不能按 8 方向切。 | Shade，[Puny Characters](https://opengameart.org/content/puny-characters)，CC0。来源压缩包保存在 `_source_archives/`。 |
| `calciumtrice_goblins/` | 小刀哥布林、装甲锤哥布林；待机、手势、走路、攻击、死亡。 | 原图 320×320，可先按 32×32 网格查看；是固定视角动作，不能直接当 4 方向图。 | Calciumtrice，[Animated Goblins](https://opengameart.org/content/animated-goblins)，CC BY 3.0。 |
| `calciumtrice_classic/` | 4 色史莱姆、骷髅、2 种兽人、牛头怪；均有待机、手势、走路、攻击、死亡。 | 通常为每行 10 帧；普通角色可先按 32×32 网格查看，牛头怪可先按 48×48。均是固定视角动作。 | Calciumtrice，[Slime](https://opengameart.org/content/animated-slime)、[Skeleton](https://opengameart.org/content/animated-skeleton)、[Orcs](https://opengameart.org/content/animated-orcs)、[Minotaur](https://opengameart.org/content/animated-minotaur)，CC BY 3.0。 |
| `calciumtrice_forest/` | 眼球、地虫、毒花、蝴蝶。包括移动、钻地、啃咬、毒气、飞行等各自不同的逐帧行为。 | 多数可先按 32×32 网格查看；各怪物动作不统一，也不是完整 4 方向图。 | Calciumtrice，[Forest Monsters](https://opengameart.org/content/forest-monsters)，CC BY 3.0。 |
| `cookieefedu_16x16/` | 2 种哥布林、骷髅、3 种史莱姆；待机、跑动、攻击、跳跃、受伤、死亡。 | 作者说明单帧 16×16、帧间距 2 像素，动作沿纵向分行。没有完整 4 方向图；配色更鲜艳，可作为候选素材。原包的 `Readme.txt` 保留在目录中。 | CookieEfedu，[Monsters Slime, Skeleton and Goblin](https://opengameart.org/content/monsters-slime-skeleton-and-goblin)，CC BY 4.0。来源压缩包保存在 `_source_archives/`。 |

## 署名

如果发布游戏并使用了 CC BY 素材，需要在游戏或随附文档中署名并附上许可链接。可使用以下文字，再按最终实际使用的图片删减：

> Monster sprites by Calciumtrice, via OpenGameArt.org, licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). Sources: Animated Goblins, Animated Slime, Animated Skeleton, Animated Orcs, Animated Minotaur, and Forest Monsters.
>
> Monster sprites by CookieEfedu, via OpenGameArt.org, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Source: Monsters Slime, Skeleton and Goblin.

Shade 的 Puny Characters 为 CC0，不要求署名。若改色、裁切或修改素材，在最终署名中标明修改情况。
