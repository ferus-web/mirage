with import <nixpkgs> { };

mkShell {
  nativeBuildInputs = [
    pkg-config
    gmp
    nph
  ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [
    gmp.dev
  ];
}
