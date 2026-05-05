{...}: {
  nix.optimise.automatic = true;
  nix.optimise.dates = ["03:45"];

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 2d";
  };
}
