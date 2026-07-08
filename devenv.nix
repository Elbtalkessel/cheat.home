{ pkgs, config, ... }: {
  packages =
    [ ]
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
    redis.enable = true;
  };
  processes = {
    devserver = {
      exec = # bash
        ''
          pushd cheat.sh/bin
            export CHEATSH_PATH_WORKDIR="${config.devenv.root}/.cheat.sh"
            python -m flask --app app.py run --reload --debug
          popd
        '';
    };
  };
  process.manager.implementation = "mprocs";
}
