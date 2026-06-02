{...}: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 443 80 20022];
  };
}
