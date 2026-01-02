{
  description = "Dan's macOS configuration with nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
    let
      system = "aarch64-darwin";
      username = "dan";
    in
    {
      darwinConfigurations = {
        # Default configuration - use hostname or "default"
        # Run: darwin-rebuild switch --flake .#default
        # Or after first build: darwin-rebuild switch --flake .
        default = nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs username; };
          modules = [
            ./darwin
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home;
              home-manager.extraSpecialArgs = { inherit inputs username; };
            }
          ];
        };
      };
    };
}
