{
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "todoart-api";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    fastapi
    uvicorn
  ];

  nativeCheckInputs = with python3Packages; [
    httpx
    pytestCheckHook
  ];

  pythonImportsCheck = ["app"];

  meta = with lib; {
    description = "FastAPI backend for TodoArt";
    mainProgram = "todoart-api";
    platforms = platforms.linux;
  };
}
