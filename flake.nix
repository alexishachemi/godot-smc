{
  description = "Godot 4.7.2-stable development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      godot-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "godot-unwrapped";
        version = "4.7.2-stable";
        src = pkgs.fetchurl {
          url = "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip";
          hash = "sha256-yt0yBOcoo10/E623/Q15AmNrefa5XEDCZetztsNTKeQ=";
        };
        nativeBuildInputs = [ pkgs.unzip ];
        unpackPhase = ''
          mkdir source
          unzip "$src" -d source
        '';
        installPhase = ''
          mkdir -p "$out/bin"
          cp "source/Godot_v4.7.2-stable_linux.x86_64" "$out/bin/godot"
          chmod +x "$out/bin/godot"
        '';
        dontStrip = true;
      };

      godot = pkgs.buildFHSEnv {
        name = "godot";
        targetPkgs = pkgs: with pkgs; [
          godot-unwrapped
          alsa-lib
          libpulseaudio
          dbus
          fontconfig
          libxkbcommon
          mesa
          udev
          libGL
          vulkan-loader
          wayland
          libx11
          libxcursor
          libxext
          libxfixes
          libxi
          libxinerama
          libxrandr
          libxrender
          speechd
        ];
        runScript = "godot";
      };

      extraTools = with pkgs; [
      ];
    in {
      packages.${system}.default = godot;
      devShells.${system}.default = pkgs.mkShell {
        packages = [ godot ] ++ extraTools;
      };
    };
}
