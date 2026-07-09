{ pkgs, config, ... }: {

  env = {
    REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    UPSTREAM_LOG_LEVEL = "INFO";
    UPSTREAM_RSS_CACHE = "true";
    UPSTREAM_REQ_CACHE = "true";
  };
  enterShell = ''
    export PATH="$DEVENV_ROOT/bin:$PATH"
    export UPSTREAM_DIR_CACHE="''${XDG_CACHE_HOME}/chtsh"
  '';

  packages =
    (with pkgs; [
      # chmod.sh:
      grc
      bc
    ])
    ++ (with pkgs.python3Packages; [
      six
      colorama
      requests
      pyicu
      redis
      gevent
      flask
      ipython
      pygments
      dateutils
      fuzzywuzzy
      colored
      langdetect
      cffi
      ltpycld2
      pyyaml
      levenshtein
      pytest
      black
      # bin/upstream dependencies
      feedparser
      markdownify
      # --
    ]);

  languages = {
    python = {
      enable = true;
      directory = "./cheat.sh";
      venv = {
        enable = true;
        requirements = ''
          polyglot
        '';
        quiet = true;
      };
    };
  };

  services = {
    redis.enable = false;
  };

  processes = {
    chtsh =
      let
        port = 5000;
      in
      {
        exec = # bash
          ''
            pushd cheat.sh
              export CHEATSH_PATH_WORKDIR="${config.devenv.root}/.cheat.sh"
              ${config.devenv.root}/.devenv/state/venv/bin/python -m flask --app bin/app.py run -p ${toString port} --reload --debug
            popd
          '';
        watch = {
          paths = [
            ./.cheat.sh/etc
            ./cheat.sh/bin
          ];
        };
        ready = {
          http.get = {
            inherit port;
            path = "/";
          };
          initial_delay = 2; # seconds before first probe (default: 0)
          period = 10; # seconds between probes (default: 10)
          probe_timeout = 1; # seconds before probe times out (default: 1)
          success_threshold = 1; # consecutive successes needed (default: 1)
          failure_threshold = 3; # consecutive failures before unhealthy (default: 3)
          timeout = 10; # Overall deadline in seconds for the process to become ready. null = no deadline.
        };
      };
  };
  process.manager.implementation = "honcho";
}
