{ pkgs, ... }: {
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
}
