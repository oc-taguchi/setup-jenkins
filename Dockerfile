FROM amazonlinux:2023

RUN dnf upgrade && \
  dnf install -y shadow-utils

RUN curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install linux \
  --extra-conf "sandbox = false" --enable-flakes --init none --no-confirm

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
