{
  git,
  nodejs_23,
  lib,
  stdenv,
  pkg-config,
  fetchFromGitHub,
  python3,
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
stdenv.mkDerivation rec {
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
    python3
    cmake
    ninja
    git
  ];

  buildInputs = [
    abseil-cpp
    spirv-headers
    spirv-tools
    glslang
    glfw
    vulkan-headers
    vulkan-utility-libraries

    python313Packages.jinja2
    pkg-config
    nodejs_23
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXinerama
    xorg.libxcb
  ];

  patchPhase = ''
    mkdir -p /build/source/third_party/khronos/OpenGL-Registry/xml
    cp ${openGLRegistry}/xml/gl.xml /build/source/third_party/khronos/OpenGL-Registry/xml
  '';

  buildPhase = ''
    mkdir -p out/Debug
    cd out/Debug
    cmake -GNinja ../..
    ninja
  '';

  #installPhase = ''
  #  mkdir -p $out/lib
  #  cp *.so* $out/lib/
  #  mkdir -p $out/include
  #  cp -r ../../src/include/* $out/include/
  #'';

  meta = with lib; {
    description = "Native WebGPU implementation";
    homepage = "https://github.com/google/dawn";
    license = licenses.bsd3;
    maintainers = with maintainers; [ unixpariah ];
    platforms = platforms.all;
  };
}
