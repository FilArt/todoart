{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.todoart-api;
  stateDir = "/var/lib/todoart-api";
in
{
  options.services.todoart-api = {
    enable = lib.mkEnableOption "TodoArt API";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../api/package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../api/package.nix { }";
      description = "The TodoArt API package to run.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address for the TodoArt API listener.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port for the TodoArt API listener.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the configured port.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        LOG_LEVEL = "info";
      };
      description = "Extra environment variables for the TodoArt API service.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.todoart-api = {
      description = "TodoArt API";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = cfg.extraEnvironment;

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "todoart-api";
        WorkingDirectory = stateDir;
        ExecStart = "${lib.getExe cfg.package} --host ${cfg.host} --port ${toString cfg.port} --db-path ${stateDir}/todoart.db";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
