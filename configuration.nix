{ lib, unstable, modulesPath, config, pkgs, ... }: {
  imports = [
    # (ssh-participation + "/module.nix")
  ];

  environment.etc = {
    "skel/.bash_profile" = {
      text = ''
        if [[ -z $TMUX ]]; then
          if ! tmux has-session -t modules 2>/dev/null; then
            tmux new-session -s modules -d /demo/bin/user-eval
            tmux split-window -t modules -b -h "bash -l; tmux kill-session -t modules"
          fi

          exec tmux attach -t modules
        fi

        cat readme
      '';
      mode = "0644";
    };
    "skel/module.nix" = {
      text = ''
        {
          departure = {
            #location = "switzerland";
          };
        }
      '';
      mode = "0644";
    };
    "skel/readme" = {
      text = ''
        Edit modules.nix with your favorite editor!
      '';
      mode = "0644";
    };
  };


  environment.systemPackages = with pkgs; [
    git
    ripgrep
    jq
    htop
    direnv

    # Wouldn't work in a nix-shell due to terminfo files needed
    kitty
  ];

  programs.bash.interactiveShellInit = ''
    eval "$(direnv hook bash)"
  '';

  nixpkgs.overlays = [(self: super: {
    inherit (unstable) wrapNeovim neovim-unwrapped neovim;
  })];

  users.users.demo = {
    isNormalUser = true;
    group = "participants";
    extraGroups = [ "wheel" "systemd-journal" ];
    uid = 1002;
    openssh.authorizedKeys.keys = with import ../../ssh-keys.nix; [ silvan ];
  };
  users.users.root.openssh.authorizedKeys.keys = with import ../../ssh-keys.nix; [ silvan ];

  security.sudo.wheelNeedsPassword = false;

  programs.command-not-found.enable = true;

  programs.tmux = {
    enable = true;
    escapeTime = 0;
    extraConfig = ''
      set -g mouse on
    '';
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    configure = {
      customRC = ''
        filetype on
        syntax enable
        filetype plugin indent on
        colorscheme gruvbox

        set tabstop=2
        set shiftwidth=2
        set hidden
        set termguicolors
        set showcmd
        set background=dark
        set mouse=a
        set undolevels=10000
        set undofile
        set nobackup
        set nowritebackup
        set number
        set expandtab

        autocmd VimEnter * :GitGutterLineNrHighlightsEnable
        set updatetime=100

        " Always enable sign column to prevent flashing with the following commands
        set signcolumn=yes
        nnoremap hb :silent !gh b<CR>:e!<CR>
        nnoremap hf :silent !gh f<CR>:e!<CR>

        " Copy to local clipboard
        autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is ''' | OSCYankReg " | endif
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          vim-nix
          editorconfig-vim
          gruvbox-community
          vim-gitgutter
          vim-oscyank
        ];
      };
    };
  };
  services.ssh-participation = {
    enable = true;
    passwordCommand = [ "${lib.getBin pkgs.coreutils}/bin/echo" "summer of nix 2021" ];
  };
  services.openssh.ports = [ 222 ];
  networking.hostName = "modules";
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes ca-references
  '';
}
