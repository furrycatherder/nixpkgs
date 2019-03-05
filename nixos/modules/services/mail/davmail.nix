{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.davmail;

  # http://davmail.sourceforge.net/serversetup.html
  configFile = pkgs.writeText "davmail.properties" ''
    davmail.server=true
    davmail.disableUpdateCheck=true

    davmail.logFilePath=/var/log/davmail/davmail.log
    davmail.logFileSize=1MB

    davmail.mode=${cfg.mode}
    davmail.url=${cfg.url}
    davmail.caldavPort=${toString cfg.ports.caldav}
    davmail.imapPort=${toString cfg.ports.imap}
    davmail.ldapPort=${toString cfg.ports.ldap}
    davmail.ports.pop=${toString cfg.ports.pop}
    davmail.ports.smtp=${toString cfg.ports.smtp}

    ${cfg.extraConfig}
  '';

in

  {
    options.services.davmail = {
      enable = mkEnableOption "davmail, an MS Exchange gateway";

      mode = mkOption {
        type = types.enum [ "auto" "EWS" "WebDav" ];
        default = "auto";
        description = "Connection mode.";
        example = "EWS";
      };

      url = mkOption {
        type = types.str;
        description = "Outlook Web Access URL to access the exchange server, i.e. the base webmail URL.";
      };

      ports = {
        caldav = mkOption {
          type = types.int;
          default = 1080;
          description = "Local Caldav/Carddav server port to configure in Caldav (calendar) or Carddav (address book) client.";
          example = 80;
        };

        imap = mkOption {
          type = types.int;
          default = 1143;
          description = "Local IMAP server port to configure in IMAP client.";
          example = 143;
        };

        ldap = mkOption {
          type = types.int;
          default = 1389;
          description = "Local LDAP server port to configure in directory (address book) client.";
          example = 389;
        };

        pop = mkOption {
          type = types.int;
          default = 1110;
          description = "Local POP server port to configure in POP client.";
          example = 110;
        };

        smtp = mkOption {
          type = types.int;
          default = 1025;
          description = "Local SMTP server port to configure in SMTP client.";
          example = 25;
        };
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration in davmail.properties.

          See http://davmail.sourceforge.net/serversetup.html and http://davmail.sourceforge.net/advanced.html for details.
        '';
        example = literalExample ''
          # allow remote connection to DavMail
          davmail.allowRemote=true
          # bind server sockets to a specific address
          davmail.bindAddress=10.0.1.2

          # let Exchange save a copy of sent messages in Sent folder
          davmail.smtpSaveInSent=true
        '';
      };
    };

    config = mkIf cfg.enable {
      systemd.services.davmail = {
        description = "DavMail POP/IMAP/SMTP Exchange Gateway";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.davmail}/bin/davmail ${configFile}";
          Restart = "on-failure";
          DynamicUser = "yes";
          LogsDirectory = "davmail";
        };
      };

      environment.systemPackages = [ pkgs.davmail ];
    };
  }
