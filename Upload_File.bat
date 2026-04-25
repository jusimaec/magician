@echo off
setlocal enabledelayedexpansion
title Github 파일 업로드 스크립트
color 0A
mode con: cols=100 lines=35

REM ========================================
REM        === 설정 변수 입력 ===
REM ========================================
REM 아래 정보를 수정하여 자신의 정보를 입력하세요
REM ========================================
set GITHUB_ACCOUNT=jusimaec
set GITHUB_REPO=magician
set GITHUB_BRANCH=main
set GIT_USER_NAME=TAEKYU OH
set GIT_USER_EMAIL=jusimaec@gmail.com
set UPLOAD_FOLDER=Program
REM ======== 업로드할 폴더명을 여기서 지정 =========

cd /d "%~dp0"

REM Git 설치 여부 확인
git --version >nul 2>&1
if errorlevel 1 (
    cls
    echo.
    echo.
    echo ========================================
    echo     Git이 설치되어 있지 않습니다
    echo ========================================
    echo.
    echo [1] Git 공식 홈페이지 ^(권장^)
    echo     https://git-scm.com/download/win
    echo.
    echo [2] Chocolatey를 이용한 설치
    echo     choco install git
    echo.
    echo [3] Windows 패키지 매니저 설치
    echo     winget install Git.Git
    echo.
    echo [4] GitHub Desktop 설치
    echo     https://desktop.github.com/
    echo.
    echo Git 설치 후 이 스크립트를 다시 실행해주세요.
    echo.
    pause
    exit /b
)

REM Git 저장소 초기화 확인
if not exist ".git" (
    echo Git 저장소 초기화 중...
    git init
    echo.
    set "repoUrl=https://github.com/!GITHUB_ACCOUNT!/!GITHUB_REPO!.git"
    echo 저장소 URL: !repoUrl!
    git remote add origin !repoUrl!
)

REM Git 사용자 정보 설정 (매번 확인)
echo [Git 사용자 정보 설정]
echo 사용자명: !GIT_USER_NAME!
echo 이메일: !GIT_USER_EMAIL!
git config user.name "!GIT_USER_NAME!"
git config user.email "!GIT_USER_EMAIL!"
echo.

REM 브랜치 이름 확인 및 변경 (master -> main)
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set CURRENT_BRANCH=%%B
if "!CURRENT_BRANCH!"=="master" (
    echo [브랜치 이름 변경: master -^> main]
    git branch -m master main
    echo.
)

:menu
cls
echo.
echo ================================
echo Github 파일 업로드 스크립트
echo ================================
echo.
echo 1. 현재 폴더의 파일 업로드
echo 2. !UPLOAD_FOLDER! 폴더의 파일 업로드
echo.
set /p uploadChoice="선택 (1 또는 2): "

if "!uploadChoice!"=="1" (
    set uploadMode=current
    set uploadDesc=현재 폴더
) else if "!uploadChoice!"=="2" (
    set uploadMode=upload
    set uploadDesc=!UPLOAD_FOLDER! 폴더
) else (
    echo.
    echo 잘못된 선택입니다.
    timeout /t 2 >nul
    goto menu
)

echo.
echo [!uploadDesc!] 파일 추가 중...

REM 스테이징 초기화
git reset 2>nul

if "!uploadMode!"=="current" (
    REM 현재 폴더의 파일만 추가 (하위폴더 제외, .bat .ps1 제외)
    for %%F in (*) do (
        if exist "%%F\" (
            echo %%F는 폴더 - 제외
        ) else (
            if "%%~xF"==".bat" (
                echo %%F는 .bat 파일 - 제외
            ) else if "%%~xF"==".ps1" (
                echo %%F는 .ps1 파일 - 제외
            ) else (
                echo 추가: %%F
                git add "%%F" 2>nul
            )
        )
    )
) else (
    REM 업로드 폴더의 파일이 있는지 확인
    if not exist "!UPLOAD_FOLDER!\*" (
        echo !UPLOAD_FOLDER! 폴더에 파일이 없습니다.
        timeout /t 2 >nul
        goto menu
    )
    
    echo [!UPLOAD_FOLDER! 폴더 파일 목록]
    dir !UPLOAD_FOLDER!
    echo.
    
    REM 폴더 구조를 유지하면서 git에 추가 (변경 사항만)
    echo [!UPLOAD_FOLDER! 폴더 전체 추가]
    git add "!UPLOAD_FOLDER!" 2>nul
)

REM 현재 tracked 파일 확인
echo [Tracked 파일 확인]
if "!uploadMode!"=="current" (
    git ls-files > temp_tracked.txt
) else (
    git ls-files !UPLOAD_FOLDER!/ > temp_tracked.txt
)
for /f "delims=" %%A in (temp_tracked.txt) do (
    echo  %%A
)
if exist temp_tracked.txt del temp_tracked.txt
echo.

REM 체크: 파일이 정말 없는지 확인
git diff --cached --name-only > temp.txt 2>nul
for /f "delims=" %%A in (temp.txt) do (
    set hasFiles=1
    goto :check_done2
)
:check_done2

REM temp.txt 파일 확인 후 삭제
if exist temp.txt (
    del temp.txt
)

REM 강제로 모든 파일을 상태로 추가
if not defined hasFiles (
    echo [최종 강제 추가]
    if "!uploadMode!"=="current" (
        git add -u . 2>nul
        git add -A . 2>nul
    ) else (
        git add -u !UPLOAD_FOLDER!/ 2>nul
        git add -A !UPLOAD_FOLDER!/ 2>nul
        git add -f !UPLOAD_FOLDER!/* 2>nul
    )
    
    REM 다시 확인
    git diff --cached --name-only > temp.txt 2>nul
    for /f "delims=" %%A in (temp.txt) do (
        set hasFiles=1
    )
    if exist temp.txt del temp.txt
)

if not defined hasFiles (
    echo.
    echo [상태 확인]
    git status
    echo.
    
    REM tracked 파일이 있는지 확인
    if "!uploadMode!"=="current" (
        git ls-files > temp.txt 2>nul
    ) else (
        git ls-files !UPLOAD_FOLDER!/ > temp.txt 2>nul
    )
    for /f "delims=" %%A in (temp.txt) do (
        set hasTrackedFiles=1
        goto :check_tracked
    )
    :check_tracked
    if exist temp.txt del temp.txt
    
    if not defined hasTrackedFiles (
        echo 추가할 파일이 없습니다.
        timeout /t 2 >nul
        goto menu
    )
    
    echo [이미 커밋된 !uploadDesc! 파일이 있습니다]
    echo 그냥 Github에 푸시하겠습니다.
    echo.
    
    REM 바로 푸시로 이동
    goto :skipCommit
)

echo.
echo 추가된 파일:
git diff --cached --name-only
echo.

echo [커밋 메시지 입력]
echo - 아무것도 입력하지 않으면 기본 메시지가 사용됩니다
echo - 예: "Upload files", "Update docs" 등
echo.
set /p commitMsg="커밋 메시지 입력 (엔터하면 기본값): "
if "!commitMsg!"=="" (
    set commitMsg=Update files from !uploadMode!
)

:skipCommit
echo.
set /p confirm="커밋 후 푸시하시겠습니까? (Y/N): "
if /i "!confirm!"=="N" (
    git reset
    goto menu
)

echo 커밋 중...
git commit -m "!commitMsg!" 2>nul

:doPush
echo.
echo *** Github 인증 정보 입력이 필요할 수 있습니다 ***
echo Personal Access Token 또는 SSH 키를 설정하세요.
echo.

REM 현재 브랜치 이름 가져오기
for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set CURRENT_BRANCH=%%B

if "!CURRENT_BRANCH!"=="" set CURRENT_BRANCH=master

echo 현재 브랜치: !CURRENT_BRANCH!
echo.

REM 원격 저장소의 최신 변경사항 가져오기
echo [원격 저장소에서 최신 변경사항 가져오는 중...]
git pull --allow-unrelated-histories origin !CURRENT_BRANCH! 2>nul
echo.

REM 현재 브랜치 푸시
git push -u origin !CURRENT_BRANCH! 2>nul

if errorlevel 1 (
    echo [재시도: 강제 푸시...]
    git push -u -f origin !CURRENT_BRANCH! 2>nul
)

if errorlevel 1 (
    echo.
    echo [첫 푸시 실패 - 브랜치 다시 시도]
    echo 기본 브랜치로 설정 중: !GITHUB_BRANCH!
    echo.
    
    REM master/main 브랜치 확인 및 설정
    git branch -m !GITHUB_BRANCH! 2>nul
    git push -u origin !GITHUB_BRANCH!
    
    if errorlevel 1 (
        echo.
        echo [오류] 푸시 실패!
        echo 다음을 확인하세요:
        echo 1. 인터넷 연결 확인
        echo 2. Github 저장소 URL: https://github.com/!GITHUB_ACCOUNT!/!GITHUB_REPO!
        echo 3. 인증 정보 설정 ^(Personal Access Token 또는 SSH^)
        echo.
        pause
        goto menu
    )
)

echo.
echo ================================
echo 완료되었습니다!
echo ================================
timeout /t 2 >nul
goto menu
