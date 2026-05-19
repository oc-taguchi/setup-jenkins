{ config, user, pkgs, lib, ... }:

let
  dotfilesDir = ../dotfiles;
  homeDir = if user == "root" then "/root" else "/home/${user}";
  jenkinsHome = "/mnt/jenkins";
in {

  home.username = user;
  home.stateVersion = "26.05";
  home.homeDirectory = homeDir;

  home.file = {
    ".config/caddy/Caddyfile".source = "${dotfilesDir}/.config/caddy/Caddyfile";
  };

  home.packages = with pkgs; [
    git
    git-lfs
    gh
    curl
    wget
    jq
    procps

    corretto25
    jenkins
    caddy
  ];

  home.sessionVariables = {
    JENKINS_HOME = jenkinsHome;
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  systemd.user.services.caddy = {
    Unit = {
      Description = "Caddy reverse proxy for Jenkins";
      After = [ "jenkins.service" ];
    };
    Service = {
      ExecStart = "${pkgs.caddy}/bin/caddy run --config ${config.home.homeDirectory}/.config/caddy/Caddyfile";
      Restart = "always";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.jenkins = {
    Unit = {
      Description = "Jenkins CI Server";
    };
    Service = {
      # JENKINS_HOME を指定してデータの場所を固定
      Environment = "JENKINS_HOME=${jenkinsHome}";
      # -Djdk.lang.Process.launchMechanism=FORK: posix_spawn が失敗する環境への対策
      # --webroot にバージョン番号を含めることで、バージョン更新時に古いキャッシュを参照しない
      ExecStart = ''
        ${pkgs.corretto25}/bin/java \
          -Djdk.lang.Process.launchMechanism=FORK \
          -jar ${pkgs.jenkins}/webapps/jenkins.war \
          --httpPort=8080 \
          --webroot=${jenkinsHome}/war-${pkgs.jenkins.version}
      '';
      Restart = "always";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
