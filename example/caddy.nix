{ pkgs, ... }:
{
  # simplest possible concrete service definition
  serviceDefs.caddy = {
    pkg = pkgs.caddy;
    args = "run -c %CFG% --adapter caddyfile";
    config.text = ''
      http://*:8888 {
      	respond "hello"
      }
    '';
  };
}
