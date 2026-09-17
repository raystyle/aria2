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
- **接线形(批2f 首建核证后裁定)**:统一发布脚本 `publish.ps1`(pwsh,工位侧)收拢三平台产出于 `dist/` 后 `gh release create dist/* --latest` 一口直发;CI 零编译零打包铁则,不采 dispatch 上传 artifact 形;构建端不持发布凭据(gh 直发与播种恒工位/仓库事件)

## 本地产出链(工位/实机)

- **mac 腿(lan-mac,已首建实证)**:`ssh lan-mac` → `~/build/aria2`(公开 clone)→ `autoreconf -i` → appletls 正形 configure → `make -j$(sysctl -n hw.ncpu)` → strip → 实机冒烟(grep -qx 对 tag 逐字)→ `tar czf` + `shasum -a 256` 边车 → 回传(见下 rsync 坑)
- **linux 腿(工位 WSL,已证形)**:`~/build/aria2-linux` + `~/build/c-ares-prefix`(24.04 无 libcares.a,源码静态编 c-ares 1.18.1 顶)→ `PKG_CONFIG_PATH=$HOME/build/c-ares-prefix/lib/pkgconfig ARIA2_STATIC=yes ./configure --without-gnutls --with-openssl --disable-websocket --disable-nls --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt` → `make -j$(nproc) LDFLAGS=-all-static` → strip → file/ldd 双断言 + 冒烟逐字 → `tar czf` + `sha256sum` 边车 → `~/linux-dist/`
- **win 腿(工位交叉,已首建实证)**:`~/build/win-deps.sh` 建 `~/build/win-prefix` 静态树(zlib 1.3.1 → c-ares 1.18.1 → sqlite autosetup 形 → openssl 3.0.16 `Configure mingw64 no-shared` → libssh2 1.11.1),`~/build/aria2-win.sh` 构 aria2(posix 线程 gcc 变体 + 官方 `ARIA2_STATIC=yes` + make 层 `-all-static` + PKG_CONFIG_LIBDIR 锁前缀),objdump import 闸零 mingw DLL(与 CI 件同形十系统 DLL);产出 `~/win-dist/`。坑账:c-ares 交叉非递归直打(SUBDIRS 命令行覆盖会传播子 make);openssl 3.0 不认 `no-docs`;win 本地件运行时冒烟缺 Windows 宿主(import 闸在,运行时验归发布窗/复验)
- **rsync 回传坑**:WSL rsync 3.x 对 lan-mac openrsync 的**目录形**协商空手(清单 0 件不报错),**逐文件显式路径**通:`rsync -v lan-mac:"build/aria2/dist/<文件>" ~/mac-dist/`(逐文件,含边车)
- **本机 clone 行尾坑**:本工位 global `core.autocrlf=true`(非仓因,CRLF 入工作树即 libtoolize 报 AC_CONFIG_MACRO_DIRS conflicts 暴毙);本地构建 clone 恒带 `-c core.autocrlf=false` 覆盖,勿动全局配置
- **统一收拢直发**:`./publish.ps1 -Tag vX.Y.Z [-DryRun]`(闸:版本一致性、逐件边车锚、包清单裸件断言、六件清点;首发专用);发布后 r2-seed 于 release published 事件自动播种。v1.37.2 三端本地件全量 DryRun 已验(闸全过未直发)

## 下版 tag 迁移序列(产地终态切窗)

1. 三平台本地产出就位(`~/mac-dist`、`~/linux-dist`、`~/win-dist` 各最新包+边车)
2. **先** commit 撤 release.yml 的 CI 编译面(build/release job;tag 触发会重建 clobber 与本地件直发相战),check 版本闸可留
3. `./publish.ps1 -Tag vX.Y.Z` 一口直发(--latest)
4. r2-seed 自动接力播种(版本段 immutable + stable 滚动,双段红灯)
5. master 顺跑 build.yml 绿留档
