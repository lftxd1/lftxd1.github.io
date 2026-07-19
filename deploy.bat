@echo off
chcp 65001 >nul
setlocal

REM ============================================================
REM  Hugo 博客一键部署
REM  Repo : https://github.com/lftxd1/lftxd1.github.io
REM  Usage: 双击 deploy.bat
REM ============================================================

set SOURCE_BRANCH=source
set DEPLOY_BRANCH=main

echo.
echo ============================================================
echo   Hugo 博客一键部署
echo ============================================================
echo.

REM ---- 配置代理（Clash/V2Ray 默认 7890，不用代理就注释掉）----
git config http.proxy http://127.0.0.1:7890
git config https.proxy http://127.0.0.1:7890

REM ---- 1. 构建（含 Pagefind）----
echo [1/4] 构建（含 Pagefind 索引）...
call npm run build
if errorlevel 1 goto :fail

REM ---- 2. 推源码到 source 分支 ----
echo.
echo [2/4] 推送源码到 %SOURCE_BRANCH% 分支...
git add -A
git diff --cached --quiet
if not errorlevel 1 goto :skip_source

set /p MSG="源码改动 - 输入提交说明 (默认: Update blog): "
if "%MSG%"=="" set MSG=Update blog
git commit -m "%MSG%"
git push origin master:%SOURCE_BRANCH%
if errorlevel 1 goto :fail

:skip_source

REM ---- 3. 部署到 main 分支 ----
echo.
echo [3/4] 部署到 %DEPLOY_BRANCH% 分支...

REM 清理可能存在的旧 worktree
cd ..
if exist gh-pages-main (
    git -C my-first-blog worktree remove --force gh-pages-main >nul 2>&1
    git -C my-first-blog branch -D %DEPLOY_BRANCH% >nul 2>&1
)

REM 新建 worktree
git -C my-first-blog worktree add -B %DEPLOY_BRANCH% gh-pages-main origin/%DEPLOY_BRANCH%
if errorlevel 1 goto :fail

cd gh-pages-main

REM 清空 worktree 内容（保留 .git）
powershell -NoProfile -Command "Get-ChildItem -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force" >nul 2>&1

REM 复制 public/* 全部内容到当前目录
xcopy /E /I /Y /Q ..\my-first-blog\public . >nul

REM 禁用 GitHub Pages 的 Jekyll 处理
type nul > .nojekyll

git add -A
git commit -m "Deploy site"
git push --force origin %DEPLOY_BRANCH%
if errorlevel 1 goto :cleanup_fail

REM ---- 4. 清理 ----
:cleanup
cd ..
git -C my-first-blog worktree remove --force gh-pages-main >nul 2>&1
git -C my-first-blog branch -D %DEPLOY_BRANCH% >nul 2>&1

echo.
echo ============================================================
echo   部署完成！
echo   等待 1-2 分钟后访问 https://lftxd1.github.io/
echo ============================================================
echo.
goto :eof

:fail
echo.
echo *** 部署失败 ***
exit /b 1

:cleanup_fail
echo.
echo *** 部署推送失败，清理 worktree ***
cd ..
git -C my-first-blog worktree remove --force gh-pages-main >nul 2>&1
git -C my-first-blog branch -D %DEPLOY_BRANCH% >nul 2>&1
exit /b 1

endlocal