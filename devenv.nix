{ pkgs, config, ... }: {
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
    chtsh = {
      exec = # bash
        ''
          pushd cheat.sh
            export CHEATSH_PATH_WORKDIR="${config.devenv.root}/.cheat.sh"
            ${config.devenv.root}/.devenv/state/venv/bin/python -m flask --app bin/app.py run --reload --debug
          popd
        '';
    };
  };
  process.manager.implementation = "honcho";
}
