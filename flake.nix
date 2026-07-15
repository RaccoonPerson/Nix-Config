{
  description = "My Nix Config for my different machines :)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # maybe some other stuff like disko and the password thingy
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let 
    system = "x86_64-linux";
  in 
  {
    nixosConfigurations = {
      archongrid = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/archongrid ];
      };

      vps = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/vps ];
      };

      homeConfigurations."racc@fedora" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home/racc/fedora.nix ];
        };
    };
  };
}