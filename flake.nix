{
  description = "Flake for sioyek PDF viewer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Add this line to import nixpkgs
  };

  outputs =
    { self, nixpkgs }:
    {
      packages.x86_64-linux.sioyek = nixpkgs.legacyPackages.x86_64-linux.stdenv.mkDerivation rec {
        pname = "sioyek";
        version = "2.0.0-r893-ga3aeca4";

        src = nixpkgs.legacyPackages.x86_64-linux.fetchFromGitHub {
          owner = "ahrm";
          repo = "sioyek";
          rev = "a3aeca4";
          sha256 = "sha256-2i54zNe8IOI80/qPTVI4iMCt5H1griDlfOHTqGw5eig="; # Replace with the actual hash
        };

        patches = [ ./standard-path-mupdf-build.patch ];

        nativeBuildInputs = with nixpkgs.legacyPackages.x86_64-linux.kdePackages; [
          qtbase
          qmake
          qtdeclarative
          qtsvg
          qtspeech
          qt3d
          nixpkgs.legacyPackages.x86_64-linux.git
	  nixpkgs.legacyPackages.x86_64-linux.installShellFiles
          wrapQtAppsHook
        ];

        buildInputs =with nixpkgs.legacyPackages.x86_64-linux; [ mupdf gumbo jbig2dec mujs openjpeg kdePackages.qt3d kdePackages.qtbase];
        postPatch = ''
          substituteInPlace pdf_viewer_build_config.pro \
            --replace "-lmupdf-threads" "-lgumbo -lharfbuzz -lfreetype -ljbig2dec -ljpeg -lopenjp2" \
            --replace "-lmupdf-third" ""
          substituteInPlace pdf_viewer/main.cpp \
            --replace "/usr/share/sioyek" "$out/share" \
            --replace "/etc/sioyek" "$out/etc"
        '';
        qmakeFlags =
          nixpkgs.legacyPackages.x86_64-linux.lib.optionals
            nixpkgs.legacyPackages.x86_64-linux.stdenv.isDarwin
            [ "CONFIG+=non_portable" ];
        postInstall =
          if nixpkgs.legacyPackages.x86_64-linux.stdenv.isDarwin then
            ''
              cp -r pdf_viewer/shaders sioyek.app/Contents/MacOS/shaders
              cp pdf_viewer/prefs.config sioyek.app/Contents/MacOS/
              cp pdf_viewer/prefs_user.config sioyek.app/Contents/MacOS/
              cp pdf_viewer/keys.config sioyek.app/Contents/MacOS/
              cp pdf_viewer/keys_user.config sioyek.app/Contents/MacOS/
              cp tutorial.pdf sioyek.app/Contents/MacOS/

              mkdir -p $out/Applications $out/bin
              cp -r sioyek.app $out/Applications
              ln -s $out/Applications/sioyek.app/Contents/MacOS/sioyek $out/bin/sioyek
            ''
          else
            ''
              install -Dm644 tutorial.pdf $out/share/tutorial.pdf
              cp -r pdf_viewer/shaders $out/share/
              install -Dm644 -t $out/etc/ pdf_viewer/{keys,prefs}.config
              installManPage resources/sioyek.1
            '';

        meta = with nixpkgs.lib; {
          description = "PDF viewer for research papers and technical books.";
          homepage = "https://github.com/ahrm/sioyek";
          license = licenses.gpl3;
          platforms = platforms.linux;
        };
      };
    };
}
