{
  description = "Cross-platform development environment using Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Systems to support
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Helper function to generate configs for multiple systems
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Helper to get pkgs for a system
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # Home Manager configurations
      homeConfigurations = {
        # Linux/Codespaces configuration
        "user@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            platform = "linux";
          };
        };

        # macOS Intel configuration
        "user@darwin-x86" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-darwin";
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            platform = "darwin";
          };
        };

        # macOS Apple Silicon configuration
        "user@darwin-arm" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "aarch64-darwin";
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            platform = "darwin";
          };
        };
      };

      # Development shell for each system
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              home-manager
              git
              pre-commit
            ];

            shellHook = ''
              echo "🏠 Nix + Home Manager development environment"
              echo "Run 'home-manager switch --flake .#<config>' to apply configuration"
              echo ""
              echo "Available configurations:"
              echo "  - user@linux (x86_64-linux)"
              echo "  - user@darwin-x86 (x86_64-darwin)"
              echo "  - user@darwin-arm (aarch64-darwin)"
            '';
          };
        }
      );
    };
}
