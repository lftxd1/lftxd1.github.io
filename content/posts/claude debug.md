+++
date = '2026-07-22T10:52:15+08:00'

title = 'Claude Debug'

+++

## 前言

Linux中Claude一直报错。

开启`claude --debug`

发现claude配置的设置不会被环境变量覆盖。





## 措施

编辑 `~/.claude/settings.json`

删除其中的默认配置。

