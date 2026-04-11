{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.pi-web-ui;

  # Create the pi-web-ui package from local build artifacts
  # This assumes the project has been built with `npm run build`
  piWebUiPkg = pkgs.stdenv.mkDerivation {
    pname = "pi-web-ui";
    version = "1.0.0";

    src = ../.;

    nativeBuildInputs = [pkgs.makeWrapper];

    buildPhase = ''
      # Verify that the build artifacts exist
      if [ ! -d "backend/dist" ]; then
        echo "ERROR: backend/dist not found. Run 'npm run build' first."
        exit 1
      fi

      if [ ! -d "frontend/dist" ]; then
        echo "ERROR: frontend/dist not found. Run 'npm run build' first."
        exit 1
      fi
    '';

    installPhase = ''
      mkdir -p $out/share/pi-web-ui

      # Copy backend files
      cp -r backend/dist $out/share/pi-web-ui/
      cp backend/package.json $out/share/pi-web-ui/

      # Copy frontend static files into backend dist folder
      # The backend serves static files from ./dist relative to working directory
      mkdir -p $out/share/pi-web-ui/dist
      cp -r frontend/dist/* $out/share/pi-web-ui/dist/

      # Create wrapper script
      mkdir -p $out/bin
      makeWrapper ${pkgs.nodejs_20}/bin/node $out/bin/pi-web-ui \
        --add-flags "$out/share/pi-web-ui/dist/index.js" \
        --set NODE_ENV production \
        --chdir "$out/share/pi-web-ui"
    '';

    meta = with lib; {
      description = "Web-based chat interface for pi-authenticated LLM providers";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in {
  options.services.pi-web-ui = {
    enable = lib.mkEnableOption "pi-web-ui - Web-based chat interface for pi-authenticated LLM providers";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for pi-web-ui service";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "hbohlen";
      description = "User to run pi-web-ui service as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group to run pi-web-ui service as";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/pi-web-ui";
      description = "Data directory for pi-web-ui service";
    };

    authFilePath = lib.mkOption {
      type = lib.types.path;
      default = "/home/hbohlen/.pi/agent/auth.json";
      description = "Path to pi agent auth.json file";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for pi-web-ui port (not recommended, use reverse proxy)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create data directory with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${cfg.user} ${cfg.group} -"
    ];

    # Main service
    systemd.services.pi-web-ui = {
      description = "pi-web-ui - Web chat interface for pi-authenticated LLMs";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "opnix-secrets.service"];
      wants = ["network.target"];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${piWebUiPkg}/bin/pi-web-ui";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;

        Environment = [
          "NODE_ENV=production"
          "PORT=${toString cfg.port}"
          "AUTH_FILE_PATH=${cfg.authFilePath}"
          "HOME=${cfg.dataDir}"
        ];

        # Restart configuration
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = "60s";
        StartLimitBurst = 3;

        # Security hardening
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = lib.mkIf (cfg.user != "hbohlen") true;
        ReadWritePaths = lib.mkIf (cfg.user != "hbohlen") [cfg.dataDir];
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        SystemCallFilter = ["@system-service" "~@privileged" "~@resources"];
        SystemCallErrorNumber = "EPERM";

        # Logging
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "pi-web-ui";
      };
    };

    # Firewall configuration (disabled by default, Caddy handles external access)
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}
