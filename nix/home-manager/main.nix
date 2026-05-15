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
      Environment = "JENKINS_HOME=${jenkinsHome}";
      # JENKINS_HOME を指定してデータの場所を固定
      ExecStart = "${pkgs.corretto25}/bin/java -jar ${pkgs.jenkins}/webapps/jenkins.war --httpPort=8080";
      Restart = "always";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
