{
  pkgs,
  config,
  ...
}: let
  appDir = "${config.devenv.root}/app";
  apiDir = "${config.devenv.root}/api";
in {
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
    buildTools.version = ["35.0.0"];
    cmake.version = [];
    extras = [];
    extraLicenses = ["android-sdk-license"];
    googleAPIs.enable = false;
    platforms.version = ["36"];

    # Keep the base shell lighter; re-enable these if you want a Nix-managed emulator.
    emulator.enable = false;
    systemImages.enable = false;
    ndk.enable = false;
    googleTVAddOns.enable = false;
  };

  scripts."flutter-doctor".exec = ''
    flutter doctor -v
  '';

  scripts."agent-supervisor-brief".exec = ''
    sed -n '1,220p' "${config.devenv.root}/AGENTS.md"
  '';

  scripts."agent-frontend-brief".exec = ''
    sed -n '1,220p' "${config.devenv.root}/app/AGENTS.md"
  '';

  scripts."agent-backend-brief".exec = ''
    sed -n '1,220p' "${config.devenv.root}/api/AGENTS.md"
  '';

  scripts."agent-workflow".exec = ''
    sed -n '1,240p' "${config.devenv.root}/docs/AGENT_WORKFLOW.md"
  '';

  scripts."flutter-create".exec = ''
    if [ -f "$APP_DIR/pubspec.yaml" ]; then
      echo "Flutter app already exists at $APP_DIR" >&2
      exit 1
    fi

    flutter create --platforms=linux,android "$APP_DIR"
  '';

  processes.api.exec = ''
    cd "$API_DIR"
    uv run fastapi dev app/main.py --host 0.0.0.0 --port 8000
  '';

  processes.app.exec = ''
    cd "$APP_DIR"
    flutter run -d linux
  '';

  enterShell = ''
    flutter config --enable-linux-desktop --enable-android >/dev/null 2>&1 || true

    echo "Flutter + FastAPI shell ready"
    echo "  app dir: $APP_DIR"
    echo "  api dir: $API_DIR"
    echo "  flutter-doctor"
    echo "  agent-supervisor-brief"
    echo "  agent-frontend-brief"
    echo "  agent-backend-brief"
    echo "  agent-workflow"
    echo "  flutter-create"
    echo "  devenv up"
    echo "  devenv test"
  '';

  enterTest = ''
    flutter --version
    uv --version
    python --version
    adb version

    cd "$APP_DIR"
    flutter test

    cd "$API_DIR"
    uv sync
    uv run pytest
  '';
}
