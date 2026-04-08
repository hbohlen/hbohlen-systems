{...}: {
  programs.ssh = {
    enable = true;
    extraConfig = ''
      IdentityAgent ~/.ssh/agent.sock
    '';
  };
}
