# FORK 维护 runbook(raystyle/aria2)

> 配方权威:project-evo build-release `references/common-contract.md` 第八节「上游追新」(ebee602,总台追正 2026-09-17);本文件为其仓级落地,不自造结构。
> 裁定档:总台核准单 2026-09-17(对齐回执批 2 f/g/h 裁定)。

## 上游追新(REQ-053 维护节)

- remote:`git remote add upstream https://github.com/aria2/aria2`(本仓现未配,首追新前加)
- 追新 = `git fetch upstream` 后 `git merge upstream/master`,merge 保审计迹为默认;追新批独立成 commit,不与功能批混
- 节奏:随上游 release tag 跟,不追上游滚动分支(压冲突面)
- 冲突面纪律:冲突只允许出现在自有改动面——`.github/workflows/`(release/r2-seed/build)、`configure.ac`(版本行、头列表拍平、ARIA2_STATIC_BUILD 定义、内部 ARC4 条件)、`src/Platform.cc`(静态构建 provider 补丁);核心源文件冲突 = 自有改动侵入过深信号,升级重评移植策略,不硬解
- 版本 bump:fork 版本沿上游序列自编(1.37.1 起 fork 先行);上游若同号发布则 fork 进位让号;`configure.ac` AC_INIT 与 tag 一致性闸照走(release.yml check job)
- 回跑矩阵:追新批必过全量回跑再发布——build.yml(master push 绿)+ release.yml 全平台构建 + 跨宿主容器闸 + 解包冒烟对 tag 逐字;上游新依赖进树仍要自含闭包(`ARIA2_STATIC=yes`,发行版 dev 包静态 .a)
- 发布:同三段式正源(过渡期 CI 编译,终态全本地,见下)

## 裁定记录(总台 2026-09-17)

- **f 产地**:终态全本地编译打包;mac 实机岗走 lan-mac mesh(舰队基建,总台辖);过渡特例 = 三平台 CI 编译在位直至 mesh 就绪
- **g 包内形态**:维持裸 aria2c 历史形豁免(存量 catalog pin 与 ark 解包契约在位);标准单顶层目录形为新品与迁版窗口缺省,本仓不回改
- **h 依赖闭包**:发行版 dev 包静态闭包豁免;权衡注记:树内 vendored 的可复现性让位于维护成本,上游手工依赖配方存档于 `mingw-build-memo`
