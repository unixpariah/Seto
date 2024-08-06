# generated by zon2nix (https://github.com/nix-community/zon2nix)

{ linkFarm, fetchzip }:

linkFarm "zig-packages" [
  {
    name = "122003818ff2aa912db37d4bbda314ff9ff70d03d9243af4b639490be98e2bfa7cb6";
    path = fetchzip {
      url = "https://github.com/luau-lang/luau/archive/refs/tags/0.607.tar.gz";
      hash = "sha256-2O+nOgOWXPEbBJlRYnW8PlpG2oeQNZB7k08lFgF+ceE=";
    };
  }
  {
    name = "12200989a0e5c5d8186dd16752e3d83d914d4f54ecca7b3e147443f13a9580ede671";
    path = fetchzip {
      url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/d8412eed455c8cfea5b4cda2ea260095ccb47045.tar.gz";
      hash = "sha256-XKpUYrd3+01SObQQZk91qgwgvpwqPmGy1cRlDRqHOFo=";
    };
  }
  {
    name = "12203fe1feebb81635f8df5a5a7242733e441fe3f3043989c8e6b4d6720e96988813";
    path = fetchzip {
      url = "https://github.com/natecraddock/lua/archive/refs/tags/5.1.5-1.tar.gz";
      hash = "sha256-/dh0sAmiHH/lP6aQq3MYXeHntwXONKPqeV9k4hhsVso=";
    };
  }
  {
    name = "122069f4b75c946c705c0ed3218f52e0917ca361f55cebf3fb1c66a431a88ccc87b3";
    path = fetchzip {
      url = "https://github.com/natecraddock/ziglua/archive/a7cf85fb871a95a46d4222fe3abdd3946e3e0dab.tar.gz";
      hash = "sha256-LtQP4v7wWywdPWJqONk/wK15E1n+ccIiiSxIoV2U3Rs=";
    };
  }
  {
    name = "1220937a223531ef6b3fea8f653dc135310b0e84805e7efa148870191f5ab915c828";
    path = fetchzip {
      url = "https://www.lua.org/ftp/lua-5.3.6.tar.gz";
      hash = "sha256-ugEt/2zqY8c4+5W9CbUvfZq0S6FBR3BxtG3bj+0m57Y=";
    };
  }
  {
    name = "1220ab835f090bde18b74191e88c4ab3bd49364d310bd9912eccebd3c47bad7957a3";
    path = fetchzip {
      url = "https://codeberg.org/ifreund/zig-wayland/archive/092e3424345d9c0a9467771b2f629fa01560a69f.tar.gz";
      hash = "sha256-ixoIWKDKm02gOSgUlhRlQuvwIc1bFXqeaOXbNjOVDwA=";
    };
  }
  {
    name = "1220ae2d84cfcc2a7aa670661491f21bbed102d335de18ce7d36866640fd9dfcc33a";
    path = fetchzip {
      url = "https://github.com/LuaJIT/LuaJIT/archive/c525bcb9024510cad9e170e12b6209aedb330f83.tar.gz";
      hash = "sha256-2C6SrzOfIaymVwXggxc0qt/O+KRRQ9JLnn23cipchdo=";
    };
  }
  {
    name = "1220d5b2b39738f0644d9ed5b7431973f1a16b937ef86d4cf85887ef3e9fda7a3379";
    path = fetchzip {
      url = "https://www.lua.org/ftp/lua-5.2.4.tar.gz";
      hash = "sha256-+GzRn/t1VyFTwGiKsZYkWynPK5ypCpzKBOYavsqWEc8=";
    };
  }
  {
    name = "1220f93ada1fa077ab096bf88a5b159ad421dbf6a478edec78ddb186d0c21d3476d9";
    path = fetchzip {
      url = "https://www.lua.org/ftp/lua-5.4.6.tar.gz";
      hash = "sha256-K2dM3q69YuOhlKKE9qTcHFJUVhjlRPxQtKB8ZQOpAyE=";
    };
  }
]
