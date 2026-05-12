{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = user: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home-manager/main.nix ];
        extraSpecialArgs = { inherit user; };
      };
    in
    {
      homeConfigurations = {
        # EC2で動かした時用
        ec2-user = mkHome "ec2-user";
        # ローカルコンテナ用
        root = mkHome "root";
      };
    };
}
