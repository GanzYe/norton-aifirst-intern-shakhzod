# Fetches llama.cpp into the flutter_llama pub-cache package (required for Android builds).
# Run after `flutter pub get` whenever flutter_llama is upgraded or pub cache is cleared.

$ErrorActionPreference = "Stop"

$llamaCppTag = "b5472"
$llamaCppRepo = "https://github.com/ggml-org/llama.cpp.git"

function Get-FlutterLlamaDir {
    $pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache" }
    $hosted = Join-Path $pubCache "hosted\pub.dev"
    if (-not (Test-Path $hosted)) {
        throw "Pub cache not found at $hosted. Run 'flutter pub get' first."
    }
    $dirs = Get-ChildItem -Path $hosted -Directory -Filter "flutter_llama-*" |
        Sort-Object Name -Descending
    if ($dirs.Count -eq 0) {
        throw "flutter_llama not in pub cache. Run 'flutter pub get' first."
    }
    return $dirs[0].FullName
}

$pluginDir = Get-FlutterLlamaDir
$llamaDir = Join-Path $pluginDir "llama.cpp"

Write-Host "flutter_llama package: $pluginDir"

function Apply-FlutterLlamaPatches {
    $patchRoot = Join-Path $PSScriptRoot "patches\flutter_llama"
    Copy-Item (Join-Path $patchRoot "android_build.gradle") (Join-Path $pluginDir "android\build.gradle") -Force
    Copy-Item (Join-Path $patchRoot "CMakeLists.txt") (Join-Path $pluginDir "android\src\main\cpp\CMakeLists.txt") -Force
    Write-Host "Applied Android build patches to flutter_llama."
}

if (Test-Path (Join-Path $llamaDir "CMakeLists.txt")) {
    Write-Host "llama.cpp already present at $llamaDir"
    Apply-FlutterLlamaPatches
    exit 0
}

Write-Host "Cloning llama.cpp (tag $llamaCppTag). This may take a few minutes..."
git clone --depth 1 --branch $llamaCppTag $llamaCppRepo $llamaDir
if ($LASTEXITCODE -ne 0) {
    Remove-Item -Recurse -Force $llamaDir -ErrorAction SilentlyContinue
    throw "git clone failed. Ensure git is installed and network is available."
}

Write-Host "Done. llama.cpp installed at $llamaDir"

Apply-FlutterLlamaPatches
