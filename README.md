## cheat.sh development / deployment

Development environment using [devenv.sh](https://devenv.sh/) and deployment using [podman](./quadlet).

### Setup

```bash
mkdir -p .cheat.sh/{etc,log,spool}
# Check cheat.sh/lib/config.py:_CONFIG for more configurations options,
# your config.yaml override them.
cat << 'EOF' > .cheat.sh/etc/config.yaml
---
server:
  # Listen on
  address: "0.0.0.0"
cache:
  # To enable, use redis. Enable service as well in devenv.nix
  type: none
upstream:
  # Default, any cht.sh servers.
  # Note: error of any kind will render "Are you offline?" banner.
  url: https://cht.sh
# Default value is bin/upstream, gitignored. cht.sh didn't release it yet.
path.internal.bin.upstream: ../bin/upstream
EOF
```

Next you can use `devenv.nix` or use its code as reference to find required packages,
environemnt variables, commands to the devserver.
