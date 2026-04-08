{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [resurrect];
    extraConfig = ''
      set -g extended-keys on
      set -g extended-keys-format csi-u
      set -g @resurrect-strategy-nvim "session"
    '';
  };
}
