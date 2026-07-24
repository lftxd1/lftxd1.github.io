+++
date = '2026-07-19T14:48:46+08:00'
draft = false
title = 'Mamba SSM环境配置'

+++

## 前言

Mamba-SSM还需要安装Causal_conv

只能通过在GitHub上下载whl文件来进行安装。



## 实际配置

即便下载了符合cuda和torch版本的mamba-ssm，依旧是失败。

**唯一成功的方案是如下配置：**

```
9527MY on Apr 3
i solve this problem.我解决了这个问题。
at cuda 12.4在cuda 12.4
pytorch 2.4
python 3.11
iintalled that我安装了那个
mamba_ssm-2.2.2+cu122torch2.4cxx11abiFALSE-cp311-cp311-linux_x86_64.whl
causal_conv1d-1.4.0+cu122torch2.4cxx11abiFALSE-cp311-cp311-linux_x86_64.whl
you can find at
你可以在
https://github.com/Dao-AlLab/causal-conv1d/releases/tag/v1.4.0https://github.com/state-spaces/mamba/releases/tag/v2.2.2L1
```

