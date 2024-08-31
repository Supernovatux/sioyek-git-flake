{
  description = "Flake for sioyek PDF viewer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Add this line to import nixpkgs
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      packages.x86_64-linux.sioyek = pkgs.stdenv.mkDerivation rec {
        pname = "sioyek";
        version = "2.0.0-r894-ga34015156";

        src = pkgs.fetchFromGitHub {
          owner = "ahrm";
          repo = "sioyek";
          rev = "4015156";
          sha256 = "sha256-2i54zNe8IOI80/qPTVI4iMCt5H1griDlfOHTqGw5eig="; # Replace with the actual hash
        };

        patches = [ ./standard-path-mupdf-build.patch ];

        nativeBuildInputs = with pkgs; [
          kdePackages.qmake
          installShellFiles
          kdePackages.wrapQtAppsHook
        ];

        buildInputs = with pkgs; [
          mupdf
          gumbo
          jbig2dec
          mujs
          openjpeg
          kdePackages.qt3d
          kdePackages.qtbase
          kdePackages.qtspeech
          kdePackages.qtwayland
        ];
        postPatch = ''
          substituteInPlace pdf_viewer_build_config.pro \
            --replace "-lmupdf-threads" "-lgumbo -lharfbuzz -lfreetype -ljbig2dec -ljpeg -lopenjp2" \
            --replace "-lmupdf-third" ""
          substituteInPlace pdf_viewer/main.cpp \
            --replace "/usr/share/sioyek" "$out/share" \
            --replace "/etc/sioyek" "$out/etc"
        '';
        postInstall = ''
          install -Dm644 tutorial.pdf $out/share/tutorial.pdf
          cp -r pdf_viewer/shaders $out/share/
          install -Dm644 -t $out/etc/ pdf_viewer/{keys,prefs}.config
          installManPage resources/sioyek.1
        '';

        meta = with nixpkgs.lib; {
          description = "PDF viewer for research papers and technical books.";
          homepage = "https://github.com/ahrm/sioyek";
          license = licenses.gpl3Only;
          platforms = platforms.linux;
        };
      };
    };
}
