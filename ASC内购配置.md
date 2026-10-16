# ASC 内购配置（App Store Connect）

> 更新时间：2026-10-16
> 全部为**消耗型项目（Consumable）**，价格单位 USD。

## 商品清单

| 序号 | 产品 ID（批次号） | 参考名称 | 价格 | 对应钻石数 | 显示名称（en_US） | 描述（en_US） | 状态 |
|------|------------------|----------|------|-----------|------------------|---------------|------|
| 1 | `lenxywkgfxfapppp` | Postcard | 0.99 | 400 | Postcard | A note from the road. | 已更新 |
| 2 | `sfvchfreqqvylbsq` | Stamp | 1.99 | 800 | Stamp | Make it official. | 已更新 |
| 3 | `com.atrim.gift.compass` | Compass | 2.99 | — | Compass | For the next wrong turn. | 保持不变 |
| 4 | `uqolhbwnthilopmj` | Pocket Map | 4.99 | 2450 | Pocket Map | Folded, torn, loved. | 已更新 |
| 5 | `hfwagmrmjavoovhr` | Thermos | 9.99 | 5150 | Thermos | For the long wait. | 已更新 |
| 6 | `hruextnukwkqbiax` | Field Notebook | 19.99 | 10800 | Field Notebook | Write it down properly. | 已更新 |
| 7 | `ygccqcprsndkwhqd` | Cabin Bag | 49.99 | 29400 | Cabin Bag | Carry-on sized gratitude. | 已更新 |
| 8 | `vlhydxmeamgmqanv` | Round Trip | 99.99 | 63700 | Round Trip | The whole journey. | 已更新 |

## ASC 配置要点

1. **类型（Type）**：全部选择 `消耗型项目（Consumable）`。
2. **产品 ID（Product ID）**：必须与上表「产品 ID（批次号）」完全一致，且与 App 内 `ATGiftCatalog.swift` 中的 `sku` 一一对应。
3. **参考名称（Reference Name）**：建议使用上表「参考名称」，仅用于 App Store Connect 后台识别。
4. **价格（Price）**：按上表价格选择对应价格档位。
5. **本地化（Localization）**：新增 `en_US`（或对应语言），显示名称与描述以上表为准。

## 备注

- 价格 **2.99（Compass）** 的商品 ID 保持原值 `com.atrim.gift.compass`，未做改动。
- 其余 7 个档位已按提供的新批次号更新，涉及文件：
  - `ATrimp/ATrimp/Models/ATGiftCatalog.swift`
  - `ATrimp/ATrimp/ATrimp.storekit`
- 应用内未使用「钻石」货币概念（当前为送礼模型），上表「对应钻石数」仅作 ASC / 运营侧记录参考。
