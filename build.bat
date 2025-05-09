@echo off
setlocal enabledelayedexpansion

:: E-Commerce Project Windows Setup and Execution Script
echo ========================================================
echo    E-Commerce Application - Complete Setup ^& Run Tool   
echo ========================================================
echo.
echo This script will:
echo  1. Check for required dependencies (Java, MySQL connector)
echo  2. Check Docker is installed and running
echo  3. Set up the database container
echo  4. Compile the Java application
echo  5. Run the application
echo.
echo You don't need to know anything about the project to use it!
echo.

:: Function to stop Docker services
:stop_docker_services
    echo Stopping Docker services...
    docker-compose down >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        docker compose down
    )
    echo Docker services stopped.
    goto :eof

:: Function to install Docker
:install_docker
    echo Installing Docker Desktop for Windows...
    
    :: Create temp directory for Docker installer
    if not exist "%TEMP%\docker-install" mkdir "%TEMP%\docker-install"
    
    :: Download Docker Desktop installer
    echo Downloading Docker Desktop installer...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile '%TEMP%\docker-install\DockerDesktopInstaller.exe' }"
    
    if exist "%TEMP%\docker-install\DockerDesktopInstaller.exe" (
        echo Docker Desktop installer downloaded successfully.
        echo Running Docker Desktop installer...
        echo Please complete the installation wizard that appears.
        
        :: Run the installer
        start "" /wait "%TEMP%\docker-install\DockerDesktopInstaller.exe"
        
        echo Docker Desktop installation completed.
        echo Please restart your computer if prompted, then run this script again.
        echo.
        echo NOTE: After restarting, make sure Docker Desktop is running
        echo       before running this script again.
    ) else (
        echo Failed to download Docker Desktop installer.
        echo Please download and install Docker Desktop manually from:
        echo https://www.docker.com/products/docker-desktop
        echo.
        echo After installation, run this script again.
    )
    goto :eof

:: Function to install Java
:install_java
    echo Java is not installed or not in PATH.
    echo.
    echo The script will download and install OpenJDK for you.
    set /p install_confirm=Would you like to install Java now? (y/n): 
    
    if /i "!install_confirm!"=="y" (
        :: Create temp directory for Java installer
        if not exist "%TEMP%\java-install" mkdir "%TEMP%\java-install"
        
        :: Download Java installer - using Adoptium OpenJDK
        echo Downloading OpenJDK installer...
        powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8%%2B7/OpenJDK17U-jdk_x64_windows_hotspot_17.0.8_7.msi' -OutFile '%TEMP%\java-install\OpenJDK17U.msi' }"
        
        if exist "%TEMP%\java-install\OpenJDK17U.msi" (
            echo OpenJDK installer downloaded successfully.
            echo Running OpenJDK installer...
            echo Please complete the installation wizard that appears.
            
            :: Run the installer
            start "" /wait "%TEMP%\java-install\OpenJDK17U.msi"
            
            echo Java installation completed.
            echo Please restart this script to use the newly installed Java.
            exit /b 1
        ) else (
            echo Failed to download OpenJDK installer.
            echo Please download and install Java manually from:
            echo https://adoptium.net/ or https://www.oracle.com/java/technologies/downloads/
            echo After installation, make sure to add Java to your PATH.
            echo Then run this script again.
            exit /b 1
        )
    ) else (
        echo Java installation skipped.
        echo Please install Java manually from:
        echo https://adoptium.net/ or https://www.oracle.com/java/technologies/downloads/
        echo After installation, make sure to add Java to your PATH.
        echo Then run this script again.
        exit /b 1
    )
    goto :eof

:: Function to install all dependencies
:install_dependencies
    echo === Installing all dependencies for the E-Commerce Project ===
    
    :: Check and install Java
    echo Checking and installing Java...
    java -version >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        call :install_java
        if %ERRORLEVEL% neq 0 (
            exit /b 1
        )
    ) else (
        echo Java is already installed.
        for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
            set JAVA_VERSION=%%g
        )
        set JAVA_VERSION=!JAVA_VERSION:"=!
        echo Using Java version: !JAVA_VERSION!
    )
    
    :: Check and install Docker
    echo Checking and installing Docker...
    docker --version >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        call :install_docker
        echo After Docker installation, run this script again.
        exit /b 1
    ) else (
        echo Docker is already installed.
    )
    
    :: Download MySQL connector
    echo Checking for MySQL connector...
    call :check_mysql_connector
    
    echo === All dependencies have been installed successfully! ===
    echo You can now run the application with build.bat
    
    exit /b 0

:: Parse command line arguments
set CLEAN=false
set DO_BUILD=true
set DO_RUN=true
set DOCKER_RESET=false
set AUTO_SHUTDOWN=false
set INSTALL_DEPS=false

:: If no arguments, run everything
if "%~1"=="" (
    set CLEAN=true
    set DO_BUILD=true
    set DO_RUN=true
) else (
    :parse_args
    if "%~1"=="--clean" (
        set CLEAN=true
        set DO_BUILD=true
        set DO_RUN=true
        shift
        goto :parse_args
    )
    if "%~1"=="--build-only" (
        set CLEAN=true
        set DO_BUILD=true
        set DO_RUN=false
        shift
        goto :parse_args
    )
    if "%~1"=="--run-only" (
        set CLEAN=false
        set DO_BUILD=false
        set DO_RUN=true
        shift
        goto :parse_args
    )
    if "%~1"=="--docker-reset" (
        set DOCKER_RESET=true
        set CLEAN=true
        set DO_BUILD=true
        set DO_RUN=true
        shift
        goto :parse_args
    )
    if "%~1"=="--auto-shutdown" (
        set AUTO_SHUTDOWN=true
        shift
        goto :parse_args
    )
    if "%~1"=="--install-dependencies" (
        set INSTALL_DEPS=true
        shift
        goto :parse_args
    )
    if "%~1"=="-i" (
        set INSTALL_DEPS=true
        shift
        goto :parse_args
    )
    if "%~1"=="--help" (
        call :print_usage
        exit /b 0
    )
)

:: Install dependencies if requested
if "%INSTALL_DEPS%"=="true" (
    call :install_dependencies
    exit /b 0
)

:: Step 1: Check for MySQL connector
call :check_mysql_connector

:: Step 2: Check Java
call :check_java

:: Step 3: Check Docker
call :check_docker

:: Step 4: Handle Docker container
if "%DOCKER_RESET%"=="true" (
    call :handle_docker reset
) else (
    call :handle_docker
)

:: Step 5: Clean if needed
if "%CLEAN%"=="true" (
    call :clean_build
)

:: Step 6: Build if needed
if "%DO_BUILD%"=="true" (
    call :compile_app
)

:: Step 7: Run if needed
if "%DO_RUN%"=="true" (
    call :run_app
)

echo === E-Commerce Application script completed! ===
exit /b 0

:: ====================== FUNCTIONS ======================

:print_usage
    echo Usage: build.bat [OPTIONS]
    echo Options:
    echo   --clean                Clean previous build artifacts
    echo   --build-only           Only compile the application without running it
    echo   --run-only             Run the application without recompiling
    echo   --docker-reset         Restart the Docker container from scratch (WARNING: resets database)
    echo   --auto-shutdown        Automatically stop Docker when application exits
    echo   --install-dependencies Install all required dependencies (Java, Docker, etc.)
    echo   -i                     Short for --install-dependencies
    echo   --help                 Show this help message
    echo.
    exit /b 0

:check_mysql_connector
    echo Checking for MySQL connector...
    
    if not exist "lib\mysql-connector-j-8.0.33.jar" (
        echo MySQL connector not found in lib directory.
        echo Downloading MySQL connector...
        
        if not exist "lib" mkdir lib
        
        :: Try to download with PowerShell
        powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar' -OutFile 'lib\mysql-connector-j-8.0.33.jar' }"
        
        if exist "lib\mysql-connector-j-8.0.33.jar" (
            echo MySQL connector downloaded successfully.
        ) else (
            echo Failed to download MySQL connector.
            echo Please download MySQL connector manually from:
            echo https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
            echo and place it in the lib directory.
            exit /b 1
        )
    ) else (
        echo MySQL connector found in lib directory.
    )
    exit /b 0

:check_java
    echo Checking if Java is installed...
    
    java -version >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo Java Development Kit (JDK) is not installed.
        echo You can run 'build.bat --install-dependencies' or 'build.bat -i' to install Java.
        set /p install_java_now=Would you like to install Java now? (y/n): 
        
        if /i "!install_java_now!"=="y" (
            call :install_java
            if %ERRORLEVEL% neq 0 (
                exit /b 1
            )
        ) else (
            echo Java is required to run this application.
            echo Please install Java manually or run this script with '--install-dependencies' flag.
            exit /b 1
        )
    )
    
    echo Java is installed.
    
    :: Get Java version
    for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        set JAVA_VERSION=%%g
    )
    set JAVA_VERSION=!JAVA_VERSION:"=!
    echo Using Java version: !JAVA_VERSION!
    
    exit /b 0

:check_docker
    echo Checking if Docker is installed...
    
    docker --version >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo Docker is not installed.
        echo You can run 'build.bat --install-dependencies' or 'build.bat -i' to install Docker.
        set /p install_docker_now=Would you like to install Docker now? (y/n): 
        
        if /i "!install_docker_now!"=="y" (
            call :install_docker
            echo After Docker installation completes, please run this script again.
            exit /b 1
        ) else {
            echo Docker is required to run this application.
            echo Please install Docker manually or run this script with '--install-dependencies' flag.
            exit /b 1
        }
    ) else (
        echo Docker is installed.
    )
    
    echo Checking if Docker daemon is running...
    
    docker info >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo Docker daemon is not running.
        echo Please start Docker Desktop manually.
        echo After starting Docker Desktop, press any key to continue or Ctrl+C to exit...
        pause >nul
        
        :: Check again
        docker info >nul 2>&1
        if %ERRORLEVEL% neq 0 (
            echo Failed to start Docker daemon. Please start it manually.
            exit /b 1
        )
    )
    
    echo Docker daemon is running.
    exit /b 0

:handle_docker
    if "%~1"=="reset" (
        echo Resetting Docker container...
        
        :: Try both docker-compose and docker compose syntax
        docker-compose down -v >nul 2>&1 
        if %ERRORLEVEL% neq 0 (
            docker compose down -v
        )
        
        docker-compose up -d >nul 2>&1
        if %ERRORLEVEL% neq 0 (
            docker compose up -d
        )
        
        echo Docker container reset. Waiting for MySQL to initialize (30 seconds)...
        timeout /t 30 /nobreak >nul
    ) else (
        :: Check if MySQL Docker container is running
        docker ps | findstr "ecommerce_db" >nul
        if %ERRORLEVEL% neq 0 (
            echo Starting MySQL Docker container...
            
            :: Try both docker-compose and docker compose syntax
            docker-compose up -d >nul 2>&1
            if %ERRORLEVEL% neq 0 (
                docker compose up -d
            )
            
            echo Waiting for MySQL to initialize (30 seconds)...
            timeout /t 30 /nobreak >nul
        ) else (
            echo MySQL Docker container is already running.
        )
    )
    
    :: Verify database connection
    echo Verifying database connection...
    docker exec ecommerce_db mysqladmin -uecomuser -pecompass ping --silent >nul
    if %ERRORLEVEL% neq 0 (
        echo Error: Cannot connect to MySQL database.
        echo Check Docker logs with: docker logs ecommerce_db
        exit /b 1
    )
    
    echo Database connection successful.
    exit /b 0

:clean_build
    echo Cleaning previous build...
    if exist dist rmdir /s /q dist
    echo Clean completed.
    exit /b 0

:compile_app
    echo Creating build directories...
    if not exist dist mkdir dist
    if not exist dist\data mkdir dist\data
    if not exist dist\lib mkdir dist\lib
    
    :: Copy data files
    if exist data (
        echo Copying data files...
        xcopy /s /y data\* dist\data\ >nul 2>&1
    )
    
    echo Compiling Java files...
    javac -d dist -cp .;lib\mysql-connector-j-8.0.33.jar Main.java Models\*.java GUI\*.java Store\*.java Interfaces\*.java utils\*.java
    
    if %ERRORLEVEL% neq 0 (
        echo Compilation failed!
        exit /b 1
    )
    
    :: Copy library files
    echo Copying library files...
    copy lib\mysql-connector-j-8.0.33.jar dist\lib\ >nul
    
    echo Build completed successfully! All class files are in the dist folder.
    exit /b 0

:run_app
    echo Running the application...
    
    cd dist
    java -cp .;lib\mysql-connector-j-8.0.33.jar Main
    cd ..
    
    echo Application exited. You can run it again with 'build.bat --run-only'

    :: Ask user if they want to stop Docker services
    if "%AUTO_SHUTDOWN%"=="true" (
        call :stop_docker_services
    ) else (
        echo Do you want to stop Docker services? (y/n)
        set /p stop_docker=
        if /i "!stop_docker!"=="y" (
            call :stop_docker_services
        ) else (
            echo Docker services will continue running in the background.
            echo To stop them later, run: docker-compose down
        )
    )
    exit /b 0