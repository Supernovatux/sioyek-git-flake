{
  description = "Flake for sioyek PDF viewer";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.sioyek = nixpkgs.lib.mkDerivation rec {
      pname = "sioyek";
      version = "2.0.0-r893-ga3aeca4";

      src = nixpkgs.fetchFromGitHub {
        owner = "ahrm";
        repo = "sioyek";
        rev = "a3aeca4";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with the actual hash
      };

      patches = [ ./standard-path-mupdf-build.patch ];

      nativeBuildInputs = [ nixpkgs.qt6.qtbase nixpkgs.qt6.qtdeclarative nixpkgs.qt6.qtsvg nixpkgs.qt6.qtspeech nixpkgs.qt6.qt3d nixpkgs.git ];

      buildInputs = [ nixpkgs.libmupdf ];

      buildPhase = ''
        cd sioyek
        qmake CONFIG+=linux_app_image pdf_viewer_build_config.pro
        make
      '';

      installPhase = ''
        make INSTALL_ROOT=$out install
        mkdir -p $out/usr/share/sioyek
        install -D tutorial.pdf $out/usr/share/sioyek/
        install -Dm644 pdf_viewer/keys.config pdf_viewer/prefs.config $out/etc/sioyek/
        install -Dm644 resources/sioyek.1 $out/usr/share/man/man1/
        mkdir -p $out/usr/share/sioyek/shaders
        cp -r pdf_viewer/shaders/* $out/usr/share/sioyek/shaders
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

