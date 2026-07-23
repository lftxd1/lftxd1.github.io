+++
date = '2026-07-23T10:52:15+08:00'

title = 'WSD 调度器：让学习率在最后才衰减的叛逆者'

+++

# WSD 调度器：让学习率在最后才衰减的叛逆者

> 训练深度学习模型时，我们习惯用 Cosine 调度让学习率平滑下降。但 WSD（Warmup-Stable-Decay）却反其道而行之——它让 LR 几乎全程保持在巅峰值，只在最后 20% 的步数里陡峭衰减。为什么这样反而更好？

---

## 一、从一次"异常"说起

几天前我在训练一个基因组语言模型，到 **53,500 步**时习惯性看了眼日志：

| step | lr | loss | acc |
|------|----|------|-----|
| 53500 | **0.0003** | 0.9219 | 59.6% |
| 53600 | **0.0003** | 0.9198 | 60.0% |
| 53650 | **0.0003** | 0.9133 | 60.4% |

五万多步了，学习率纹丝不动？马上检查了代码——不是 Bug。

训练配置是 `--max-steps 75000 --warmup-ratio 0.10 --decay-ratio 0.20`，对应 WSD 调度器的三个阶段：

| 阶段 | 步骤范围 | LR | 含义 |
|------|---------|-----|------|
| **Warmup** | 0 → 7,500 | 0 → 3e-4（线性上升） | 预热 |
| **Stable** | 7,500 → 60,000 | **3e-4（不变）** | 稳定高 LR 学习 |
| **Decay** | 60,000 → 75,000 | 3e-4 → 1.5e-5（inverse-sqrt） | 衰减 |

53,500 步时我才刚走完 ~89% 的 stable 阶段。LR 要到 **60,000 步**才开始衰减。

这与我们熟知的 Cosine 调度大相径庭——若用 Cosine，同样配置在 53,500 步时 LR 已从 3e-4 衰减到约 1.5e-4，足足掉了一半。

---

## 二、WSD 调度器到底是什么

WSD 由 **Warmup + Stable + Decay** 三段组成，概念上简单得令人难以置信：

### 数学形式

```
                ┌ (step+1) / warmup,            if step < warmup
lr_lambda(n) =  ├ 1.0,                           if step < decay_start
                └ 1 - scale * (1 - 1/√t),        otherwise (t = step - decay_start + 1)
```

### 三段详解

1. **Warmup（预热）**：线性从 0 爬到峰值 LR。与所有调度器一样，避免初始梯度爆炸。
2. **Stable（稳定期）**：**全程保持峰值 LR 不变**。这是 WSD 的灵魂——模型在最高效的探索速率下学完绝大部分知识。
3. **Decay（衰减期）**：使用 inverse-sqrt（反平方根）快速衰减到最低 LR（通常是峰值的 5%）。衰减曲线非常陡峭——前几步就把 LR 打了下去。

```
LR
↑
3e-4 ┤          ███████████████████████████████████
     │         ██                                        ↘
     │        █                                            ↘
     │    ███                                                ↘
 1e-5 ┤█                                                      █████
     └───┬─────┬─────────────────────────┬─────────────────┬───→ step
         0   7.5k                      60k               65k  75k
     Warmup     Stable                    Decay
```

### 参数控制

通常两个 ratio 参数就够了：

```python
def build_wsd_scheduler(optimizer, total_steps, warmup_ratio=0.10, decay_ratio=0.20):
    warmup = max(1, int(total_steps * warmup_ratio))
    decay  = max(1, int(total_steps * decay_ratio))
    stable = max(0, total_steps - warmup - decay)
    ...
```

- `warmup_ratio`：预热占比（常见 0.01~0.10）
- `decay_ratio`：衰减占比（常见 0.10~0.30）
- 稳定期占比 = 1 - warmup_ratio - decay_ratio

---

## 三、为什么 WSD 这样设计？

要理解 WSD，先想一个问题：**在整个训练过程中，每条样本被模型"看到"时，它贡献的梯度更新幅度是均匀的吗？**

### Cosine 调度的问题

Cosine 的 LR 从峰值开始，以优美的余弦曲线逐渐下降：

```
LR
↑
3e-4 ┤    ████
     │   █    ██
     │  █       ██
     │ █          ███
     │█              █████
 1e-5 ┤                   ██████████
     └─────────────────────────────────→ step
```

训练到一半时 LR 已经降了不少。这意味着：
- **中后期的样本以较低的 LR 更新模型**，它们的"话语权"天然更小
- 如果某个重要概念恰好在中后期出现，模型能从中学习的幅度有限

但训练数据在送入顺序上是随机的——没有理由让前一半样本比后一半样本更重要。Cosine 调度在无形中给训练数据赋予了不均衡的权重。

### WSD 的哲学

WSD 的观点是：**在整个训练过程中，让每条样本在模型上施加的梯度更新幅度基本一致。**

- **Stable 阶段**：LR 恒定，每个 step 的更新步长大致相等。模型在所有样本上以统一的探索力度进行学习。
- **Decay 阶段**：仅仅在最后做一个"收尾整理"——告诉模型"差不多该收敛了"，让参数靠近一个锐利的最小值。这个阶段很短，因为那是整理工作，不是学习工作。

### 为什么 decay 可以这么晚、这么短？

WSD 的 Decay 阶段相当于**在稳定期结束后的独立冷却**。一个关键性质是：**即使你在 stable 阶段中途中断训练，单独加一段 cooldown，模型性能也能恢复绝大部分。**

这在 MiniMA 论文中有详细论证——stable 阶段学到的知识是核心，decay 只是在已有知识上做了一次"聚焦"。这意味着你在 stable 阶段跑了 10 万步还是 20 万步，decay 的时间不需要成比例增加，固定几千步的 inverse-sqrt 衰减就够了。

---

## 四、WSD vs 常见调度器

| 特性 | Cosine | Linear Decay | **WSD** |
|------|--------|--------------|---------|
| 高 LR 占比 | ~50% steps < peak×0.7 | ~30% steps < peak×0.7 | **~80% steps = peak** |
| 衰减形状 | 余弦平滑下降 | 线性下降 | **陡峭 inverse-sqrt（最后）** |
| 调参难度 | 低 | 低 | 低 |
| 训练中途中断可恢复性 | 中 | 中 | **高（可补 decay）** |
| 对 warmup 步数敏感度 | 低 | 低 | 低 |
| 主流应用 | 几乎所有 CV 任务 | 部分 NLP 任务 | **LLaMA、MiniMA、ICML 论文** |

### 在 loss landscape 上的直觉

想象模型训练是在一张地形图上找最低点：

- **Cosine**：前期大步快走，中期步伐渐小，后期小步慢走。你在中后期看到一块有潜力的区域，但步子已经迈不大了。
- **WSD**：用最大步幅一直探索到最后一刻，然后猛踩刹车、小步挪到最近的谷底。你的探索时间更长，找到好谷底的概率更高。

---

## 五、实际使用经验

### 如何配置 WSD

```bash
# 典型的 WSD 配置
torchrun --nproc_per_node=4 train.py \
    --max-steps 100000 \
    --lr 3e-4 \
    --warmup-ratio 0.05 \
    --decay-ratio 0.15
```

- **warmup_ratio**：5%~10% 够用，除非你用了特殊的参数初始化。
- **decay_ratio**：10%~20% 最常见。`0.20` 是安全的默认值——decay 期有足够的步数让 inverse-sqrt 把 LR 降到底。
- **min_lr_ratio**：通常设置为峰值 LR 的 5%。如果觉得 final loss 还有下降空间，可以降到 1% 甚至 0%。

### 如果你觉得 decay 太晚

WSD 的参数直观且正交——修改 decay_ratio 完全不影响 warmup 和 stable 的行为，它只是把 stable 砍掉一部分给 decay：

```
# decay 提前：decay_ratio=0.35
# warmup=7.5k, decay=26.25k, stable=41.25k
# decay 从 48,750 步开始

# decay 更早：decay_ratio=0.50
# warmup=7.5k, decay=37.5k, stable=30k
# decay 从 37,500 步开始
```

### 在 V38 训练中的表现

回到开头的训练案例，V38 配置 `warmup=0.10, decay=0.20, total=75000`：

| Step Range | LR | 发生了什么 |
|-----------|-----|----------|
| 0 → 7.5k | 0 → 3e-4 | Warmup，loss 从初始值快速下降 |
| 7.5k → 60k | **3e-4 恒定** | 稳定学习，acc 从 ~30% 稳步提升到 ~65% |
| 60k → 75k | 3e-4 → 1.5e-5 | 快速衰减，模型收敛到最优 |

日志验证了预期：53500 步时 LR=3e-4，loss 仍在下降，acc 仍在上升——模型还没学完，高 LR 有充分价值。

---

## 六、延展阅读

- **MiniMA**：最早系统论证 WSD 有效性的工作之一，展示了 cooldown 的可插拔特性。
- **LLaMA 系列**：使用了类似 WSD 的调度策略，stable 阶段占据了训练过程的绝大部分。
- **WSD 的 cooldown 独立性**：stable 阶段结束后，你可以尝试不同长度的 cooldown，甚至使用不同的 decay 函数——这个特性在实验设计上非常灵活。

---

## 总结

WSD 调度器的核心理念可以浓缩为一句话：

**用高 LR 学完大部分知识，只在最后做一次收尾整理。**

它放弃 cosine 的平滑渐进，换来了：

1. **算力利用率更高** — 80% 的时间在峰值 LR
2. **数据权重更均匀** — 每条样本的影响力相近
3. **更灵活的实验** — 训练中途中断后，补一段 cooldown 即可恢复性能

如果你的训练使用 cosine 或 linear decay，不妨试试 WSD——你可能会惊讶于它在相同步数下跑出的更好结果。而当你看到日志中 LR 久高不下时，至少知道：嗯，这就是 WSD 想要的。

---

*附：一个最小 WSD 实现（~30 行）：*

```python
import math
from torch.optim.lr_scheduler import LambdaLR

def build_wsd_scheduler(optimizer, total_steps, warmup_ratio=0.10,
                         decay_ratio=0.20, min_lr_ratio=0.05):
    warmup = max(1, int(total_steps * warmup_ratio))
    decay  = max(1, int(total_steps * decay_ratio))
    stable = max(0, total_steps - warmup - decay)
    decay_start = warmup + stable

    denom = (1.0 - 1.0 / math.sqrt(decay)) if decay > 1 else 1.0
    scale = (1.0 - min_lr_ratio) / denom if denom > 0 else 0.0

    def lr_lambda(step):
        if step < warmup:
            return (step + 1) / float(warmup)          # linear 0→1
        if step < decay_start:
            return 1.0                                   # plateau
        t = (step - decay_start) + 1                     # 1..decay
        raw = 1.0 / math.sqrt(max(1.0, float(t)))
        return 1.0 - scale * (1.0 - raw)                 # scaled inverse-sqrt

    return LambdaLR(optimizer, lr_lambda=lr_lambda)
```

## 收尾阶段Inverse-sqrt 存在的问题

默认的Inverse-sqrt 策略让学习率下降得太剧烈了。

- Inverse-sqrt 的问题：99% 的衰减工作在前 100 步就完成了，后面 14,900 步的 LR 几乎等于最低值，浪费了算力。

- Cosine decay 的好处：LR 直到 5000 步才明显下降，有更多时间在较高 LR 下学习，而且全程平滑。

- Liner下降：匀速下降。

  ```
  Liner decay 阶段 15,000 步的 LR 变化：
  
  60000 (decay开始)  3.00e-04  ████████████████████████
  61000 (+1000步)    2.81e-04  ███████████████████████  降了 6%
  62000 (+2000步)    2.62e-04  ██████████████████████   降了 13%
  64000 (+4000步)    2.24e-04  ██████████████████       降了 25%
  65000 (+5000步)    2.05e-04  ████████████████         降了 32%
  67500 (+7500步)    1.57e-04  █████████████            降了 48%
  70000 (+10000步)   1.10e-04  █████████                降了 63%
  72500 (+12500步)   6.25e-05  █████                    降了 79%
  75000 (decay结束)  1.50e-05  █                        降了 95%
  ```

  

