#!/usr/bin/env pwsh
# 统一发布脚本(总台裁定 2026-09-17 接线形):三平台本地产出收拢 dist/ → gh release create 一口直发
# 铁则:CI 零编译零打包(编译打包恒本地);直发与播种恒工位/仓库事件,构建端不持发布凭据
# 收拢源:mac = ~/mac-dist(lan-mac 产出回传),linux = ~/linux-dist,win = ~/win-dist,各取最新包+边车
# 闸:configure.ac 版本一致性 + 逐件 sha256sum -c 边车锚 + 包清单断言裸 aria2c(.exe) + 六件清点
# 用法:./publish.ps1 -Tag v1.37.3 [-DryRun];发布后 R2 播种由 r2-seed workflow 于 release published 事件自动接力
param(
  [Parameter(Mandatory = $true)][string]$Tag,
  [switch]$DryRun,
  [string]$MacDist = "$HOME/mac-dist",
  [string]$LinuxDist = "$HOME/linux-dist",
  [string]$WinDist = "$HOME/win-dist"
)
$ErrorActionPreference = 'Stop'
$Repo = $PSScriptRoot
$Ver = $Tag.TrimStart('v')

# 1 版本一致性闸(tag 对 configure.ac,同 release.yml check job)
$init = Select-String -Path (Join-Path $Repo 'configure.ac') -Pattern 'AC_INIT\(\[aria2\],\[([0-9.]+)\]' | Select-Object -First 1
if (-not $init -or $init.Matches[0].Groups[1].Value -ne $Ver) {
  throw "tag $Tag 与 configure.ac $($init.Matches[0].Groups[1].Value) 不符"
}

function Get-LatestPair([string]$Dir, [string]$Glob) {
  $pkg = Get-ChildItem -Path $Dir -Filter $Glob -File |
    Where-Object { $_.Name -notlike '*.sha256' } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $pkg) { throw "$Dir 无 $Glob 产出" }
  $side = "$($pkg.FullName).sha256"
  if (-not (Test-Path $side)) { throw "$($pkg.Name) 缺 .sha256 边车" }
  [pscustomobject]@{ Pkg = $pkg; Side = Get-Item $side }
}

function Assert-Anchor($pair) {
  Push-Location $pair.Pkg.DirectoryName
  try {
    sha256sum -c $pair.Side.Name | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "边车锚不过:$($pair.Pkg.Name)" }
  } finally { Pop-Location }
}

# 2 三平台收拢,逐件过闸
$legs = @(
  @{ Stage = $MacDist;   Glob = 'aria2-aarch64-apple-darwin.tar.gz';     Kind = 'tar' },
  @{ Stage = $LinuxDist; Glob = 'aria2-x86_64-unknown-linux-gnu.tar.gz'; Kind = 'tar' },
  @{ Stage = $WinDist;   Glob = 'aria2-x86_64-pc-windows-gnu.zip';       Kind = 'zip' }
)
$dist = Join-Path $Repo 'dist'
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Path $dist | Out-Null
foreach ($leg in $legs) {
  $pair = Get-LatestPair $leg.Stage $leg.Glob
  Assert-Anchor $pair
  if ($leg.Kind -eq 'tar') {
    $list = @(tar tzf $pair.Pkg.FullName)
    if ($list.Count -ne 1 -or $list[0] -ne 'aria2c') { throw "tar 清单非裸 aria2c:$($pair.Pkg.Name) → $($list -join ',')" }
  } else {
    $list = @(unzip -Z1 $pair.Pkg.FullName)
    if ($list.Count -ne 1 -or $list[0] -ne 'aria2c.exe') { throw "zip 清单非裸 aria2c.exe:$($pair.Pkg.Name) → $($list -join ',')" }
  }
  Copy-Item $pair.Pkg.FullName $dist
  Copy-Item $pair.Side.FullName $dist
  Write-Host "收拢 $($pair.Pkg.Name)($($pair.Pkg.Length)B)锚过清单过"
}

# 3 六件清点(三包 + 三边车)
$files = @(Get-ChildItem $dist -File)
if ($files.Count -ne 6) { throw "dist 件数 $($files.Count) 非 6" }
$files | Format-Table Name, Length | Out-String | Write-Host

# 4 一口直发(本脚本只首发;已存在即止红,重铸走工位手工流程)
if ($DryRun) { Write-Host 'DRY RUN:闸全过,未直发'; exit 0 }
gh release view $Tag *> $null
if ($LASTEXITCODE -eq 0) { throw "release $Tag 已存在(首发专用,勿重复)" }
gh release create $Tag @((Get-ChildItem $dist -File).FullName) --latest --title "aria2 $Tag" `
  --notes "raystyle fork 自建全平台编译(linux/win 全静态单可执行,mac 原生 appletls;三平台本地产出,工位一口直发)。资产三包加逐件 .sha256 边车。"
if ($LASTEXITCODE -ne 0) { throw 'gh release create 失败' }
Write-Host "已直发 $Tag(--latest);R2 播种由 r2-seed 于 release published 事件自动接力"
