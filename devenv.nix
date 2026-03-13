{ pkgs, config, ... }:

let
  appDir = "${config.devenv.root}/app";
  apiDir = "${config.devenv.root}/api";
in
{
  env = {
    APP_DIR = appDir;
    API_DIR = apiDir;
    JAVA_HOME = pkgs.jdk17.home;
  };

  packages = with pkgs; [
    git
    clang
    cmake
    ninja
    pkg-config
    gtk3
    libGLU
    jdk17
    mesa-demos
  ];

  languages.python = {
    enable = true;
    package = pkgs.python312;
    uv.enable = true;
  };

  android = {
    enable = true;
    flutter.enable = true;
    buildTools.version = [ "35.0.0" ];
    cmake.version = [ ];
    extras = [ ];
    extraLicenses = [ "android-sdk-license" ];
    googleAPIs.enable = false;
    platforms.version = [ "36" ];

    # Keep the base shell lighter; re-enable these if you want a Nix-managed emulator.
    emulator.enable = false;
    systemImages.enable = false;
    ndk.enable = false;
    googleTVAddOns.enable = false;
  };

  scripts."flutter-doctor".exec = ''
    flutter doctor -v
  '';

  scripts."flutter-create".exec = ''
    if [ -f "$APP_DIR/pubspec.yaml" ]; then
      echo "Flutter app already exists at $APP_DIR" >&2
      exit 1
    fi

    flutter create --platforms=linux,android "$APP_DIR"
  '';

  scripts."app-run-linux".exec = ''
    if [ ! -f "$APP_DIR/pubspec.yaml" ]; then
      echo "Missing Flutter project at $APP_DIR. Run flutter-create first." >&2
      exit 1
    fi

    cd "$APP_DIR"
    flutter run -d linux
  '';

  scripts."app-run-android".exec = ''
    if [ ! -f "$APP_DIR/pubspec.yaml" ]; then
      echo "Missing Flutter project at $APP_DIR. Run flutter-create first." >&2
      exit 1
    fi

    cd "$APP_DIR"
    flutter run -d android
  '';

  scripts."app-test".exec = ''
    if [ ! -f "$APP_DIR/pubspec.yaml" ]; then
      echo "Missing Flutter project at $APP_DIR. Run flutter-create first." >&2
      exit 1
    fi

    cd "$APP_DIR"
    flutter test
  '';

  scripts."api-sync".exec = ''
    if [ ! -f "$API_DIR/pyproject.toml" ]; then
      echo "Missing FastAPI project at $API_DIR. Create pyproject.toml first." >&2
      exit 1
    fi

    cd "$API_DIR"
    uv sync
  '';

  scripts."api-run".exec = ''
    if [ ! -f "$API_DIR/app/main.py" ]; then
      echo "Missing FastAPI entrypoint at $API_DIR/app/main.py." >&2
      exit 1
    fi

    cd "$API_DIR"
    uv run fastapi dev app/main.py --host 0.0.0.0 --port 8000
  '';

  scripts."api-test".exec = ''
    if [ ! -f "$API_DIR/pyproject.toml" ]; then
      echo "Missing FastAPI project at $API_DIR. Create pyproject.toml first." >&2
      exit 1
    fi

    cd "$API_DIR"
    uv sync
    uv run pytest
  '';

  scripts."test-all".exec = ''
    app-test
    api-test
  '';

  processes.api.exec = ''
    if [ ! -f "$API_DIR/app/main.py" ]; then
      echo "Missing FastAPI entrypoint at $API_DIR/app/main.py." >&2
      exit 1
    fi

    cd "$API_DIR"
    uv run fastapi dev app/main.py --host 0.0.0.0 --port 8000
  '';

  enterShell = ''
    flutter config --enable-linux-desktop --enable-android >/dev/null 2>&1 || true

    echo "Flutter + FastAPI shell ready"
    echo "  app dir: $APP_DIR"
    echo "  api dir: $API_DIR"
    echo "  flutter-doctor"
    echo "  flutter-create"
    echo "  app-run-linux"
    echo "  app-run-android"
    echo "  app-test"
    echo "  api-sync"
    echo "  api-run"
    echo "  api-test"
    echo "  test-all"
    echo "  devenv up api"
  '';

  enterTest = ''
    flutter --version
    uv --version
    python --version
    adb version
  '';
}
