+++
date = '2026-07-24T22:51:10+08:00'
draft = true
title = 'Claude如何节省toekn'

+++

## 调节思考强度

` vim ~/.claude/settings.json`

设置`"CLAUDE_CODE_EFFORT_LEVEL": "high"` 而非max

```


 
"env": {
    "ANTHROPIC_AUTH_TOKEN": "PROXY_MANAGED",
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:15721",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4-5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME": "deepseek-v4-flash",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_NAME": "deepseek-v4-flash",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-8",
    "ANTHROPIC_DEFAULT_OPUS_MODEL_NAME": "deepseek-v4-flash",
    "CLAUDE_CODE_EFFORT_LEVEL": "high"
  }
```

## Caveman Skill



### 通用自动安装（推荐）

这个方法最简单，它会自动检测你电脑上支持的 AI 编程助手（如 Claude Code, Cursor, Codex 等），并一次性完成安装。

- **macOS / Linux / WSL**：
  在终端中运行以下命令：

  ```
  curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
  ```

  

- **Windows (PowerShell)**：
  在 PowerShell 中运行以下命令：

  ```
  irm https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.ps1 | iex
  ```

### 如何生效与使用

安装完成后，Caveman Skill 的使用非常灵活。

- **默认自动生效**：安装后，在 **Claude Code、Codex 和 Gemini** 中，Caveman 模式**默认就是激活的**，从第一条消息开始就会生效，无需额外操作。
- **手动控制**：你也可以通过对话命令随时开启或关闭。
  - **开启**：输入 `/caveman` 或直接说 “talk like caveman”。
  - **关闭**：说 “stop caveman” 或 “normal mode”。
- **调整强度**：Caveman 支持多种压缩强度，可以通过命令切换。
  - `/caveman lite`：轻度压缩，去掉填充词，保留基本语法。
  - `/caveman full`：经典模式，默认选项。
  - `/caveman ultra`：极限压缩，用箭头等符号表达因果关系。
  - `/caveman wenyan`：文言文模式。

### 查看节省了多少token

` /caveman:caveman-stats`

```
● UserPromptSubmit operation blocked by hook:
  Caveman Stats
  ──────────────────────────────────
  Session:  ...me/b5d1195d-a827-42a4-83ca-7f1883d2898a.jsonl
  Turns:    42
  ──────────────────────────────────
  Output tokens:         41,550
  Cache-read tokens:     744,064
  ──────────────────────────────────
  Est. without caveman:  118,714
  Est. tokens saved:     77,164 (~65% of output)
  Savings est. from benchmarks/ (mean per-task). Actual varies by task. Reduction is of output tokens only; input/cache usage is unchanged.

  Original prompt: /caveman:caveman-stats
```

可以看出节省了65%。

