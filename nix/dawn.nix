{
  git,
  nodejs,
  lib,
  stdenv,
  pkg-config,
  fetchFromGitHub,
  python313,
  cmake,
  ninja,
  xorg,
  python313Packages,
  abseil-cpp,
  spirv-headers,
  spirv-tools,
  glslang,
  glfw,
  vulkan-headers,
  vulkan-utility-libraries,
}:

let
  openGLRegistry = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "OpenGL-Registry";
    rev = "master";
    sha256 = "19al214l3badsm1kgb9gpjp5v7m07z6slkph4ma1bnnivrjpqfrl";
  };
in
stdenv.mkDerivation {
  pname = "libdawn";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "dawn";
    rev = "cf1b10b81c4305dc9daca07422aad494f8351ef4";
    sha256 = "076l1yf3ggrnn8h9dxmni4ay89x8qnysifaplzp9a2k7skkr9kc3";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    python313
    cmake
    ninja
    git
    pkg-config
    python313Packages.jinja2
    nodejs
  ];

  buildInputs = [
    abseil-cpp
    spirv-headers
    spirv-tools
    glslang
    glfw
    vulkan-headers
    vulkan-utility-libraries
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXinerama
    xorg.libxcb
  ];

  patches = [
  ];

  postPatch = ''
    mkdir -p third_party/khronos/OpenGL-Registry/xml
    cp ${openGLRegistry}/xml/gl.xml third_party/khronos/OpenGL-Registry/xml
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DDAWN_ENABLE_PIC=ON"
    "-DDAWN_BUILD_EXAMPLES=OFF"
    "-DDAWN_ENABLE_STATIC=OFF"
    "-DDAWN_USE_X11=ON"
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p out/Release && cd out/Release
    cmake -GNinja ../.. \
      -DCMAKE_INSTALL_PREFIX=$out \
      ''${cmakeFlags.join(" ")}
    ninja
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ninja install
    runHook postInstall
  '';

  meta = with lib; {
    description = "Native WebGPU implementation";
    homepage = "https://github.com/google/dawn";
    license = licenses.bsd3;
    maintainers = with maintainers; [ unixpariah ];
    platforms = platforms.linux; # Adjust if cross-platform
  };
}
