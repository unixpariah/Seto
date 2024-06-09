{
  lib,
  linkFarm,
  fetchurl,
  fetchgit,
  runCommandLocal,
  zig,
  name ? "zig-packages",
}:
with builtins;
with lib; let
  unpackZigArtifact = {
    name,
    artifact,
  }:
    runCommandLocal name {
      nativeBuildInputs = [zig];
    } ''
      hash="$(zig fetch --global-cache-dir "$TMPDIR" ${artifact})"
      mv "$TMPDIR/p/$hash" "$out"
      chmod 755 "$out"
    '';

  fetchZig = {
    name,
    url,
    hash,
  }: let
    artifact = fetchurl {inherit url hash;};
  in
    unpackZigArtifact {inherit name artifact;};

  fetchGitZig = {
    name,
    url,
    hash,
  }: let
    parts = splitString "#" url;
    base = elemAt parts 0;
    rev = elemAt parts 1;
  in
    fetchgit {
      inherit name rev hash;
      url = base;
      deepClone = false;
    };

  fetchZigArtifact = {
    name,
    url,
    hash,
  }: let
    parts = splitString "://" url;
    proto = elemAt parts 0;
    path = elemAt parts 1;
    fetcher = {
      "git+http" = fetchGitZig {
        inherit name hash;
        url = "http://${path}";
      };
      "git+https" = fetchGitZig {
        inherit name hash;
        url = "https://${path}";
      };
      http = fetchZig {
        inherit name hash;
        url = "http://${path}";
      };
      https = fetchZig {
        inherit name hash;
        url = "https://${path}";
      };
      file = unpackZigArtifact {
        inherit name;
        artifact = /. + path;
      };
    };
  in
    fetcher.${proto};
in
  linkFarm name [
    {
      name = "1220f40881b248c7d1a74e679cdb6c6c13c493a350deddbfeeb7aef92c03321ae5a6";
      path = fetchZigArtifact {
        name = "giza";
        url = "https://github.com/unixpariah/giza/archive/zig-0.12.0.tar.gz";
        hash = "sha256-EMqaIUlEUbhShxSIrijCH3OoiLiq/OQQW6U/oU+xz1I=";
      };
    }
    {
      name = "122079a0dd43f5b26a584f2cde6c2580de775ed5e1b48d80e9946eef3edc4a510a04";
      path = fetchZigArtifact {
        name = "ziglua";
        url = "https://github.com/natecraddock/ziglua/archive/41a110981cf016465f72208c3f1732fd4c92a694.tar.gz";
        hash = "sha256-eXCZQ+/0MiIRQxwtYv9PzWJvSEGZKmrGywi5P+6EQXo=";
      };
    }
    {
      name = "12203fe1feebb81635f8df5a5a7242733e441fe3f3043989c8e6b4d6720e96988813";
      path = fetchZigArtifact {
        name = "lua51";
        url = "https://github.com/natecraddock/lua/archive/refs/tags/5.1.5-1.tar.gz";
        hash = "sha256-jbS/40hxBzC+mREiYjLh3qHn/yRvkeFiKjA3FqwIL50=";
      };
    }
    {
      name = "1220d5b2b39738f0644d9ed5b7431973f1a16b937ef86d4cf85887ef3e9fda7a3379";
      path = fetchZigArtifact {
        name = "lua52";
        url = "https://www.lua.org/ftp/lua-5.2.4.tar.gz";
        hash = "sha256-ueLkqtZ4mztjoFbUQveznw7Pyjrg8fwK5OlhRAG2n0s=";
      };
    }
    {
      name = "1220937a223531ef6b3fea8f653dc135310b0e84805e7efa148870191f5ab915c828";
      path = fetchZigArtifact {
        name = "lua53";
        url = "https://www.lua.org/ftp/lua-5.3.6.tar.gz";
        hash = "sha256-/F/Wm7hzYyPwJmcrG3I12mE9cXfnJViJOgvc0yBGbWA=";
      };
    }
    {
      name = "1220f93ada1fa077ab096bf88a5b159ad421dbf6a478edec78ddb186d0c21d3476d9";
      path = fetchZigArtifact {
        name = "lua54";
        url = "https://www.lua.org/ftp/lua-5.4.6.tar.gz";
        hash = "sha256-fV6huctqoLWco93hxq3LV++DobqOVDLA7NBr9DmzrYg=";
      };
    }
    {
      name = "122003818ff2aa912db37d4bbda314ff9ff70d03d9243af4b639490be98e2bfa7cb6";
      path = fetchZigArtifact {
        name = "luau";
        url = "https://github.com/luau-lang/luau/archive/refs/tags/0.607.tar.gz";
        hash = "sha256-UZQJ19u0PaEzkBMakMgxyw8qucJeM3rPFVCDE6M5vzY=";
      };
    }
    {
      name = "1220b0f8f822c1625af7aae4cb3ab2c4ec1a4c0e99ef32867b2a8d88bb070b3e7f6d";
      path = fetchZigArtifact {
        name = "zig-wayland";
        url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.1.0.tar.gz";
        hash = "sha256-YPYimMooQ8xclCn74uTP2mGKGefnB+xTvHROUVTEQsY=";
      };
    }
    {
      name = "1220840390382c88caf9b0887f6cebbba3a7d05960b8b2ee6d80567b2950b71e5017";
      path = fetchZigArtifact {
        name = "zig-xkbcommon";
        url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.1.0.tar.gz";
        hash = "sha256-SgcHvYkzed8BmX75w7WwFZL+SCz9EFjOHcvMy45d0bY=";
      };
    }
  ]
