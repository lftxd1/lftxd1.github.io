@echo off
setlocal

REM Auto cd to script's own directory so it works from any cwd
cd /d "%~dp0"

REM ============================================================
REM  Hugo blog one-click deploy
REM  Repo : https://github.com/lftxd1/lftxd1.github.io
REM  Usage: double-click deploy.bat or run it in cmd
REM ============================================================

set SOURCE_BRANCH=source
set DEPLOY_BRANCH=main

echo.
echo ============================================================
echo   Hugo blog deploy
echo ============================================================
echo.

REM ---- Proxy (comment out if not needed) ----
git config http.proxy http://127.0.0.1:7890
git config https.proxy http://127.0.0.1:7890

REM ---- 1. Build (hugo + pagefind) ----
echo [1/4] Building site (Hugo + Pagefind)...
call npm run build
if errorlevel 1 goto :fail

REM ---- 2. Push source to source branch ----
echo.
echo [2/4] Pushing source to %SOURCE_BRANCH% branch...
git add -A
git diff --cached --quiet
if not errorlevel 1 goto :skip_source

set /p MSG="Source changed - enter commit message (default: Update blog): "
if "%MSG%"=="" set MSG=Update blog
git commit -m "%MSG%"
git push origin master:%SOURCE_BRANCH%
if errorlevel 1 goto :fail

:skip_source

REM ---- 3. Deploy to main branch ----
echo.
echo [3/4] Deploying to %DEPLOY_BRANCH% branch...

REM Clean up any leftover worktree from a previous failed run
cd ..
if exist gh-pages-main (
    git -C my-first-blog worktree remove --force gh-pages-main >nul 2>&1
    git -C my-first-blog branch -D %DEPLOY_BRANCH% >nul 2>&1
)

REM Create worktree for main branch
git -C my-first-blog worktree add -B %DEPLOY_BRANCH% gh-pages-main origin/%DEPLOY_BRANCH%
if errorlevel 1 goto :fail

cd gh-pages-main

REM Clear worktree contents (keep .git)
powershell -NoProfile -Command "Get-ChildItem -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force" >nul 2>&1

REM Copy public/* contents into current dir
xcopy /E /I /Y /Q ..\my-first-blog\public . >nul

REM Disable Jekyll processing on GitHub Pages
type nul > .nojekyll

git add -A
git commit -m "Deploy site"
git push --force origin %DEPLOY_BRANCH%
if errorlevel 1 goto :cleanup_fail

REM ---- 4. Cleanup ----
:cleanup
cd ..
git -C my-first-blog worktree remove --force gh-pages-main >nul 2>&1
git -C my-first-blog branch -D %DEPLOY_BRANCH% >nul 2>&1

echo.
echo ============================================================
echo   Deploy complete!
echo   Wait 1-2 minutes, then visit https://lftxd1.github.io/
echo ============================================================
echo.
goto :eof

:fail
echo.
echo *** DEPLOY FAILED ***
exit /b 1

:cleanup_fail
echo.
echo *** PUSH FAILED - cleaning up worktree ***
cd ..
git -C my-first-blog worktree remove --force gh-pages-main >nul 2>&1
git -C my-first-blog branch -D %DEPLOY_BRANCH% >nul 2>&1
exit /b 1

endlocal