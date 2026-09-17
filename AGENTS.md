# AGENTS(raystyle/aria2 fork)

## Commands

- 维护全流程(上游追新、三端本地产出链、发布迁移序列)见 `MAINTENANCE.md`
- 发布:`./publish.ps1 -Tag vX.Y.Z [-DryRun]`(四闸;直发后 r2-seed 自动播种)
- CI 结论:`gh run` 自取;发布回执 digest 一律 `gh api` 自取

## Must

- **缺陷反馈统一走舰队 issue 入口**(REQ-057,issues.ohmygh.com):`omc issue new "<标题>" --tool aria2 --body "<描述>"`
  - body 首行带 aria2 实际版本(如 `aria2 1.37.2`)——代发时 version 字段记的是 omc 自身版本,aria2 版本以 body 为准
  - 查件 `omc issue list --tool aria2`,详情 `omc issue show <id>`
- 自含纪律:linux/win 全静态免宿主 DSO(坑账见 MAINTENANCE.md);发布走 publish.ps1 四闸
- 改动守冲突面纪律:自有面 = workflows / configure.ac(版本行、头列表拍平、静态定义、内部 ARC4 条件)/ Platform.cc 补丁

## Must not

- CI 零编译零打包(编译打包恒本地);产物零 commit 回仓
- 勿侵入上游核心源加戏(如给 aria2c 加子命令面——issue 反馈走 omc 代发轻量形,即本仓 REQ-057 裁形)
- 勿动 ohmycloud catalog(总台辖)

## Read first

- `MAINTENANCE.md`(维护 runbook:裁定档、产出链命令面、坑账、下版 tag 迁移序列)

## 环境

- 工位 WSL:注意 global `core.autocrlf=true`,本地构建 clone 恒 `-c core.autocrlf=false`
- mac 实机 `ssh lan-mac`(`~/build/aria2`);win 交叉 `~/build/win-prefix` + `~/build/aria2-win.sh`
