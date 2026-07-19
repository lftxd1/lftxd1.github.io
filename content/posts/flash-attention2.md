+++
date = '2026-07-18T21:52:15+08:00'

title = 'Flash Attention2 快速安装'

+++

## 前言

直接使用 `pip install flash-attn` 经常会遇到各种各样的报错，不推荐把报错信息交给AI解决，因为它们往往会乱答给出不管用的 fix。我建议直接前往官方仓库下载适配的 wheel 文件并用其进行安装。访问官方仓库的 release 页面：[https://github.com/Dao-AILab/flash-attention/releases](https://link.zhihu.com/?target=https%3A//github.com/Dao-AILab/flash-attention/releases) ，可以看到许多批不同版本的 [flash-attn](https://zhida.zhihu.com/search?content_id=268997872&content_type=Article&match_order=2&q=flash-attn&zd_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ6aGlkYV9zZXJ2ZXIiLCJleHAiOjE3ODQ1NTQ1MjgsInEiOiJmbGFzaC1hdHRuIiwiemhpZGFfc291cmNlIjoiZW50aXR5IiwiY29udGVudF9pZCI6MjY4OTk3ODcyLCJjb250ZW50X3R5cGUiOiJBcnRpY2xlIiwibWF0Y2hfb3JkZXIiOjIsInpkX3Rva2VuIjpudWxsfQ.jNTb2B4uAgwt8X24HEO0T1fvfTxV3-rPaNbu4sx5dwg&zhida_source=entity) ，再点开 Assets 就能看见该版本具体兼容的各个文件，我们需要选择一个适配的。



一个典型的 flash-attn `.whl` 的文件名如 `flash_attn-2.7.3+cu11torch2.6cxx11abiFALSE-cp312-cp312-linux_x86_64.whl` 记录了该 `.whl` 文件对应的安装环境， “flash_attn-**2.7.3**+cu**11**torch**2.6**cxx11abi**FALSE**-cp**312**-cp**312**” 其中 **标黑下划线** 的各部分是我们要着重查明的。

## 确定配置

### 1. Python 版本

在终端进入环境输入指令：

```text
python --version
```

返回如：

```text
Python 3.12.9
```



### 2. CUDA 版本

输入指令：

```text
nvcc -V
```

返回如：

```text
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2022 NVIDIA Corporation
Built on Wed_Sep_21_10:33:58_PDT_2022
Cuda compilation tools, release 11.8, V11.8.89
Build cuda_11.8.r11.8/compiler.31833905_0
```

这里查询的是**系统本地**安装的 **NVIDIA [CUDA Toolkit](https://zhida.zhihu.com/search?content_id=268997872&content_type=Article&match_order=1&q=CUDA+Toolkit&zd_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ6aGlkYV9zZXJ2ZXIiLCJleHAiOjE3ODQ1NTQ1MjgsInEiOiJDVURBIFRvb2xraXQiLCJ6aGlkYV9zb3VyY2UiOiJlbnRpdHkiLCJjb250ZW50X2lkIjoyNjg5OTc4NzIsImNvbnRlbnRfdHlwZSI6IkFydGljbGUiLCJtYXRjaF9vcmRlciI6MSwiemRfdG9rZW4iOm51bGx9.QuaBnGH2aw1M07mVeb0-MgfmcyNAr0Og1LI2RTCTaKQ&zhida_source=entity)** 版本。可以看出此处 CUDA 版本为 11.8 ，对应 cu**11** ；如果 CUDA 版本为 12.x 则对应 cu**12** 。

### 3. [PyTorch](https://zhida.zhihu.com/search?content_id=268997872&content_type=Article&match_order=1&q=PyTorch&zd_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ6aGlkYV9zZXJ2ZXIiLCJleHAiOjE3ODQ1NTQ1MjgsInEiOiJQeVRvcmNoIiwiemhpZGFfc291cmNlIjoiZW50aXR5IiwiY29udGVudF9pZCI6MjY4OTk3ODcyLCJjb250ZW50X3R5cGUiOiJBcnRpY2xlIiwibWF0Y2hfb3JkZXIiOjEsInpkX3Rva2VuIjpudWxsfQ.74mY9bxoJ948H2axQi0SQnDdWkMSGSL8byoyr6-XuQI&zhida_source=entity) 版本

输入指令：

```text
python -c "import torch; print(torch.__version__);"
```

返回如：

```text
2.6.0+cu124
```

前面是 [pytorch](https://zhida.zhihu.com/search?content_id=268997872&content_type=Article&match_order=1&q=pytorch&zd_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ6aGlkYV9zZXJ2ZXIiLCJleHAiOjE3ODQ1NTQ1MjgsInEiOiJweXRvcmNoIiwiemhpZGFfc291cmNlIjoiZW50aXR5IiwiY29udGVudF9pZCI6MjY4OTk3ODcyLCJjb250ZW50X3R5cGUiOiJBcnRpY2xlIiwibWF0Y2hfb3JkZXIiOjEsInpkX3Rva2VuIjpudWxsfQ.4xGQqsGmSZaJffbqgWcyTBWZJHklsgu5XfIa5guYsr0&zhida_source=entity) 版本，对应 torch**2.6** ；

后面 cu124 是 PyTorch **运行时需要**的 CUDA 版本，我们不关心。这里可能与你前面查询到的本地 CUDA 版本不一致，不一定影响使用，先往后看，你不放心可以重装符合本地 CUDA 版本的 torch 全家桶。

### 4. Flash Attention 版本

这是我们要选择去装的 flash-attn 版本，通常会在你要配置的模型的 `requirements.txt` 中标出来，如 `flash-attn==2.7.3` 等等，对应 flash_attn-**2.7.3** ，更高版本的也能选，更低版本的也许也能用。如果没有标明，自行翻阅各版本，选择出能符合前面三项配置的。`.post1` 之类代表这是修订版。



## 搬运说明

搬运自 https://zhuanlan.zhihu.com/p/1994754750374244794
