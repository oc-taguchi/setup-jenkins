{ config, user, pkgs, lib, ... }:

let
  dotfilesDir = ../dotfiles;
  homeDir = if user == "root" then "/root" else "/home/${user}";
  jenkinsHome = "${homeDir}/.jenkins";
in {

  home.username = user;
  home.stateVersion = "26.05";
  home.homeDirectory = homeDir;

  home.file = {
    ".config/nginx/nginx.conf".source = "${dotfilesDir}/.config/nginx/nginx.conf";
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
    nginx
  ];

  home.sessionVariables = {
    JENKINS_HOME = jenkinsHome;
  };

  programs.home-manager.enable = true;

  home.activation.unprivilegedPorts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ "$(sysctl -n net.ipv4.ip_unprivileged_port_start)" -gt 80 ]; then
      echo "net.ipv4.ip_unprivileged_port_start = 80" | sudo tee /etc/sysctl.d/99-unprivileged-ports.conf > /dev/null
      sudo sysctl --system > /dev/null
    fi
  '';

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  systemd.user.services.nginx = {
    Unit = {
      Description = "nginx reverse proxy for Jenkins";
      After = [ "jenkins.service" ];
    };
    Service = {
      ExecStart = "${pkgs.nginx}/bin/nginx -c ${config.home.homeDirectory}/.config/nginx/nginx.conf -g 'daemon off;'";
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
