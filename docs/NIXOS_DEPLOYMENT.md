# NixOS Deployment

`./api` is now directly packageable as a Nix package.

## Build the package

From the repo root:

```sh
nix-build ./api
```

That produces an executable at `result/bin/todoart-api`.

Example local run:

```sh
result/bin/todoart-api --host 127.0.0.1 --port 8000 --db-path ./todoart.db
```

## Use it in NixOS

Import the module from this repo:

```nix
{
  imports = [
    /srv/todoart/nix/todoart-api-module.nix
  ];

  services.todoart-api = {
    enable = true;
    package = pkgs.callPackage /srv/todoart/api/package.nix { };
    host = "127.0.0.1";
    port = 8000;
  };
}
```

The service:

- runs `todoart-api` under systemd
- stores its SQLite database at `/var/lib/todoart-api/todoart.db`
- restarts automatically on failure

If you want the API reachable directly from the network, set:

```nix
services.todoart-api.openFirewall = true;
```

Extra environment variables can be passed through:

```nix
services.todoart-api.extraEnvironment = {
  EXAMPLE_FLAG = "1";
};
```
