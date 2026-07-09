{ pkgs, config, ... }: {

  env = {
    # Allows using custom certificate authority in case
    # if want to use your own upstream server,
    # read about upstream servers in README.md.
    REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    # Check bin/upstream for explanation.
    UPSTREAM_LOG_LEVEL = "INFO";
    UPSTREAM_RSS_CACHE = "true";
    UPSTREAM_REQ_CACHE = "true";
    # Configs, logs, spool
    CHEATSH_PATH_WORKDIR = "${config.devenv.root}/.cheat.sh";
    CHEATSH_ADAPTER_QUESTION_OUTPUT_FORMAT = "code";
  };
  # Add local bin directory to path for easier debugging
  # and sets cache directory for the upstream binary, also
  # for easier debugging when developing upstream result scrapper.
  enterShell = ''
    export PATH="$DEVENV_ROOT/bin:$PATH"
    export UPSTREAM_DIR_CACHE="''${XDG_CACHE_HOME}/chtsh"
  '';

  # For no particular reason cheat.sh/requirements.txt are mostly
  # ignored, python depdendencies are installed from the nix packages.
  packages =
    (with pkgs; [
      # chmod.sh:
      grc
      bc
      # lib/fmt/comments.py dependency,
      # Broken, but left for future reference, hangs on request.
      # Using basic heuristic comments.py classifies
      # each line as a code or text, using vim + nerdcommenter plugin comments
      # text blocks producing valid code output.
      # Invoked when adapter has `_output_format` set to `text+code` from lib/postprocessing.
      ((vim.override { }).customize {
        name = "vim";
        # Install plugins for example for syntax highlighting of nix files
        vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
          start = [ nerdcommenter ];
          opt = [ ];
        };
      })
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
        # Dependencies that are non package for nix.
        # Note: there is ltpycld2 on nixpkgs, but its interface differs from the pycld2 from pypi.
        requirements = ''
          polyglot
          pycld2
        '';
        quiet = true;
      };
    };
  };

  scripts = {
    "r-docker".exec = "docker --config ${config.devenv.root}/.cheat.sh/docker";
    "r-docker-build" = {
      exec = # bash
        ''
          pushd $(readlink cheat.sh)
            docker build . --tag quay.io/glazing2928/chtsh:latest
          popd
        '';
    };
    "r-docker-up" = {
      exec = # bash
        ''
          pushd $(readlink cheat.sh)
            docker compose up -d
          popd
        '';
    };
    "r-docker-up-debug" = {
      exec = # bash
        ''
          pushd $(readlink cheat.sh)
            docker compose -f docker-compose.yml -f docker-compose.debug.yml up -d
          popd
        '';
    };
  };

  services = {
    redis.enable = true;
  };
  processes = {
    # Local dev server, reloads on code, binary and config file changes.
    #
    # Flask is invoked by explicitly specifying python path, without
    # it nix can pick unrelated python path a system one for example.
    #
    # To start it use `devenv up`, process manager is mediocre and may
    # behave bad on sigterm sometimes hunging,
    # ps aux | grep '[c]htsh' | awk '{print $2}' | head -n1 | xargs -I{} kill -9 {}
    chtsh =
      let
        port = 5000;
      in
      {
        exec = # bash
          ''
            pushd cheat.sh
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
