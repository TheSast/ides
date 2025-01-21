{
  pkg = pkgs.caddy;
  args = "run -c %CFG% --adapter caddyfile";
  config = ''
    http://*:8080 {
    	respond "hello"
    }
  '';
}
