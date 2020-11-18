{ config, pkgs, lib
, ...}@args:
with lib;
{
  # Choose your themee
  themes.base16 = {
    enable = true;
    scheme = "solarized";
    variant = "solarized-dark";

    # Add extra variables for inclusion in custom templates
    extraParams = {
      fontname = mkDefault  "Inconsolata LGC for Powerline";
  #headerfontname = mkDefault  "Cabin";
      bodysize = mkDefault  "10";
      headersize = mkDefault  "12";
      xdpi= mkDefault ''
            Xft.hintstyle: hintfull
      '';
    };
  };
  nixpkgs.overlays = [
    (import ./overlay.nix)
    (final: prev: {
      pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
    })
  ];
  services.gpg-agent.pinentryFlavor = lib.mkForce "curses";

  programs.home-manager.enable = true;

  programs.bash.enable = true;
  programs.bash.bashrcExtra = /*(homes.withoutX11 args).programs.bash.initExtra +*/ ''
    if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
      source $HOME/.nix-profile/etc/profile.d/nix.sh
    fi
    export NIX_IGNORE_SYMLINK_STORE=1 # aloy

    export PATH=$HOME/bin:$PATH
  '';


  #programs.bash.historySize = 50000;
  #programs.bash.historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
  #programs.bash.historyIgnore = [ "ls" "cd" "clear" "[bf]g" ];

  home.sessionVariables.HISTCONTROL="erasedups:ignoredups:ignorespace";
  home.sessionVariables.HISTFILE="$HOME/.bash_history";
  home.sessionVariables.HISTFILESIZE="";
  home.sessionVariables.HISTIGNORE="ls:cd:clear:[bf]g";
  home.sessionVariables.HISTSIZE="";

  programs.bash.shellAliases.ls="ls --color";

  programs.bash.initExtra = ''
    # Provide a nice prompt.
    PS1=""
    PS1+='\[\033[01;37m\]$(exit=$?; if [[ $exit == 0 ]]; then echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗ $exit"; fi)'
    PS1+='$(ip netns identify 2>/dev/null)' # sudo setfacl -m u:$USER:rx /var/run/netns
    PS1+=' ''${GIT_DIR:+ \[\033[00;32m\][$(basename $GIT_DIR)]}'
    PS1+=' ''${ENVRC:+ \[\033[00;33m\]env:$ENVRC}'
    PS1+=' ''${SLURM_NODELIST:+ \[\033[01;34m\][$SLURM_NODELIST]\[\033[00m\]}'
    PS1+=' \[\033[00;32m\]\u@\h\[\033[01;34m\] \W '
    if !  command -v __git_ps1 >/dev/null; then
      if [ -e $HOME/code/git-prompt.sh ]; then
        source $HOME/code/git-prompt.sh
      fi
    fi
    if command -v __git_ps1 >/dev/null; then
      PS1+='$(__git_ps1 "|%s|")'
    fi
    PS1+='$\[\033[00m\] '

    export PS1
    case $TERM in
      dvtm*|st*|rxvt|*term)
        trap 'echo -ne "\e]0;$BASH_COMMAND\007"' DEBUG
      ;;
    esac

    eval "$(${pkgs.coreutils}/bin/dircolors)"
    export BASE16_SHELL_SET_BACKGROUND=false
    source ${config.lib.base16.base16template "shell"}

    export TODOTXT_DEFAULT_ACTION=ls
    alias t='todo.sh'

    tput smkx
  '';

  home.file.".vim/base16.vim".source = config.lib.base16.base16template "vim";
  #config.lib.base16.base16template "vim";

  programs.git.enable = true;
  programs.git.package = pkgs.gitFull;
  programs.git.userName = "David Guibert";
  programs.git.userEmail = "david.guibert@gmail.com";
  programs.git.aliases.files = "ls-files -v --deleted --modified --others --directory --no-empty-directory --exclude-standard";
  programs.git.aliases.wdiff = "diff --word-diff=color --unified=1";
  #programs.git.ignores
  programs.git.iniContent.clean.requireForce = true;
  programs.git.iniContent.rerere.enabled = true;
  programs.git.iniContent.rerere.autoupdate = true;
  programs.git.iniContent.rebase.autosquash = true;
  programs.git.iniContent.credential.helper = "password-store";
  programs.git.iniContent."url \"software.ecmwf.int\"".insteadOf = "ssh://git@software.ecmwf.int:7999";
  programs.git.iniContent.color.branch = "auto";
  programs.git.iniContent.color.diff = "auto";
  programs.git.iniContent.color.interactive = "auto";
  programs.git.iniContent.color.status = "auto";
  programs.git.iniContent.color.ui = "auto";
  programs.git.iniContent.diff.tool = "vimdiff";
  programs.git.iniContent.diff.renames = "copies";
  programs.git.iniContent.merge.tool = "vimdiff";

  # http://ubuntuforums.org/showthread.php?t=1150822
  ## Save and reload the history after each command finishes
  home.sessionVariables.PROMPT_COMMAND="history -a; history -c; history -r";
  home.sessionVariables.SQUEUE_FORMAT="%.18i %.25P %35j %.8u %.2t %.10M %.6D %.6C %.6z %.15E %20R %W";
 #home.sessionVariables.SINFO_FORMAT="%30N  %.6D %.6c %15F %10t %20f %P"; # with state
  home.sessionVariables.SINFO_FORMAT="%30N  %.6D %.6c %15F %20f %P";
  home.sessionVariables.PATH="$HOME/bin:$PATH";
  home.sessionVariables.MANPATH="$HOME/man:$MANPATH:/share/man";
  home.sessionVariables.PAGER="less -R";
  home.sessionVariables.EDITOR="vim";
  home.sessionVariables.GIT_PS1_SHOWDIRTYSTATE=1;
  # ✗ 1    dguibert@vbox-57nvj72 ~ $ systemctl --user status
  # Failed to read server status: Process org.freedesktop.systemd1 exited with status 1
  # ✗ 130    dguibert@vbox-57nvj72 ~ $ export XDG_RUNTIME_DIR=/run/user/$(id -u)
  home.sessionVariables.XDG_RUNTIME_DIR="/run/user/$(id -u)";

  # Fix stupid java applications like android studio
  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";

  home.packages = with pkgs; [
    (vim_configurable.override {
      guiSupport = "no";
      gtk2=null; gtk3=null;
      libX11=null; libXext=null; libSM=null; libXpm=null; libXt=null; libXaw=null; libXau=null; libXmu=null;
      libICE=null;
    })

    rsync

    gitAndTools.gitRemoteGcrypt
    gitAndTools.git-crypt

    gnumake
    #nix-repl
    pstree

    screen
    #teamviewer
    tig
    lsof
    #haskellPackages.nix-deploy
    htop
    tree

    #wpsoffice
    file
    bc
    unzip

    sshfsFuse

    moreutils

    editorconfig-core-c
    todo-txt-cli
    ctags
    dvtm
    gnupg1compat

    nix
    gitAndTools.git-annex
    gitAndTools.hub
    gitAndTools.git-crypt
    gitFull #guiSupport is harmless since we also installl xpra
    (pkgs.writeScriptBin "git-annex-diff-wrapper" ''
      #!${runtimeShell}
      LANG=C ${diffutils}/bin/diff -u "$1" "$2"
      exit 0
    '')
    python3Packages.datalad
    subversion
    tig
    jq
    lsof
    #xpra
    htop
    tree

    # testing (removed 20171122)
    #Mitos
    #MemAxes
    python3
  ];

  programs.direnv.enable = true;

  services.gpg-agent.enable = true;
  services.gpg-agent.enableSshSupport = true;
  # https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/
  home.file.".gnupg/gpg.conf".text = ''
    # Avoid information leaked
    no-emit-version
    no-comments
    export-options export-minimal

    # Displays the long format of the ID of the keys and their fingerprints
    keyid-format 0xlong
    with-fingerprint

    # Displays the validity of the keys
    list-options show-uid-validity
    verify-options show-uid-validity

    # Limits the algorithms used
    personal-cipher-preferences AES256
    personal-digest-preferences SHA512
    default-preference-list SHA512 SHA384 SHA256 RIPEMD160 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed

    cipher-algo AES256
    digest-algo SHA512
    cert-digest-algo SHA512
    compress-algo ZLIB

    disable-cipher-algo 3DES
    weak-digest SHA1

    s2k-cipher-algo AES256
    s2k-digest-algo SHA512
    s2k-mode 3
    s2k-count 65011712
  '';


  home.file.".inputrc".text = ''
    set show-all-if-ambiguous on
    set visible-stats on
    set page-completions off
    # https://git.suckless.org/st/file/FAQ.html
    set enable-keypad on
    # http://www.caliban.org/bash/
    #set editing-mode vi
    #set keymap vi
    #Control-o: ">&sortie"
    "\e[A": history-search-backward
    "\e[B": history-search-forward
    "\e[1;5A": history-search-backward
    "\e[1;5B": history-search-forward

    # Arrow keys in keypad mode
    "\C-[OA": history-search-backward
    "\C-[OB": history-search-forward
    "\C-[OC": forward-char
    "\C-[OD": backward-char

    # Arrow keys in ANSI mode
    "\C-[[A": history-search-backward
    "\C-[[B": history-search-forward
    "\C-[[C": forward-char
    "\C-[[D": backward-char

    # mappings for Ctrl-left-arrow and Ctrl-right-arrow for word moving
    "\e[1;5C": forward-word
    "\e[1;5D": backward-word
    #"\e[5C": forward-word
    #"\e[5D": backward-word
    "\e\e[C": forward-word
    "\e\e[D": backward-word

    $if mode=emacs

    # for linux console and RH/Debian xterm
    "\e[1~": beginning-of-line
    "\e[4~": end-of-line
    "\e[5~": beginning-of-history
    "\e[6~": end-of-history
    "\e[7~": beginning-of-line
    "\e[3~": delete-char
    "\e[2~": quoted-insert
    "\e[5C": forward-word
    "\e[5D": backward-word
    "\e\e[C": forward-word
    "\e\e[D": backward-word
    "\e[1;5C": forward-word
    "\e[1;5D": backward-word

    # for rxvt
    "\e[8~": end-of-line

    # for non RH/Debian xterm, can't hurt for RH/DEbian xterm
    "\eOH": beginning-of-line
    "\eOF": end-of-line

    # for freebsd console
    "\e[H": beginning-of-line
    "\e[F": end-of-line
    $endif
  '';

  # mimeapps.list
  # https://github.com/bobvanderlinden/nix-home/blob/master/home.nix
  home.keyboard.layout = "fr";

  programs.tmux.enable = true;
  programs.tmux.sensibleOnTop = false;
  programs.tmux.plugins = with pkgs; [
    tmuxPlugins.copycat
    {
      plugin=tmuxPlugins.pain-control;
      extraConfig="set-option -g @pane_resize '10'";
    }
    #{
    #  plugin = tmuxPlugins.resurrect;
    #  extraConfig = "set -g @resurrect-strategy-nvim 'session'";
    #}
    #{
    #  plugin = tmuxPlugins.continuum;
    #  extraConfig = ''
    #    set -g @continuum-restore 'on'
    #    set -g @continuum-save-interval '60' # minutes
    #  '';
    #}
  ];
  programs.tmux.extraConfig = ''
    source-file ${config.lib.base16.base16template "tmux"}

    set -g prefix C-a
    # ============================================= #
    # Start with defaults from the Sensible plugin  #
    # --------------------------------------------- #
    run-shell ${pkgs.tmuxPlugins.sensible.rtp}
    # ============================================= #
    # new window and retain cwd
    bind c new-window -c "#{pane_current_path}"

    # Prompt to rename window right after it's created
    #set-hook -g after-new-window 'command-prompt -I "#{window_name}" "rename-window '%%'"'

    # Rename session and window
    bind r command-prompt -I "#{window_name}" "rename-window '%%'"
    bind R command-prompt -I "#{session_name}" "rename-session '%%'"

    # =====================================
    # ===        Renew environment      ===
    # =====================================
    set -g update-environment \
      "DISPLAY\
      SSH_CLIENT\
      SSH_ASKPASS\
      SSH_AUTH_SOCK\
      SSH_AGENT_PID\
      SSH_CONNECTION\
      SSH_TTY\
      WINDOWID\
      XAUTHORITY"

    bind '$' run "~/.tmux/renew_env.sh"

    # Enable mouse support
    set -g mouse on

    # Reload tmux configuration
    bind C-r source-file ~/.tmux.conf \; display "Config reloaded"

    # Link window
    bind L command-prompt -p "Link window from (session:window): " "link-window -s %% -a"

    # ==============================================
    # ===   Nesting local and remote sessions     ===
    # ==============================================
    set -g status-position top

    # Session is considered to be remote when we ssh into host
    if-shell 'test -n "$SSH_CLIENT"' \
        'source-file ~/.tmux/tmux.remote.conf'

    # We want to have single prefix key "C-a", usable both for local and remote session
    # we don't want to "C-a" + "a" approach either
    # Idea is to turn off all key bindings and prefix handling on local session,
    # so that all keystrokes are passed to inner/remote session

    # see: toggle on/off all keybindings · Issue #237 · tmux/tmux - https://github.com/tmux/tmux/issues/237
    # TODO: highlighted for nested local session as well
    wg_is_keys_off="#[fg=$color_light,bg=$color_window_off_indicator]#([ $(tmux show-option -qv key-table) = 'off' ] && echo 'OFF')#[default]"
    if-shell 'test -e ~/.tmux/status.conf' 'source-file ~/.tmux/status.conf'

    # Also, change some visual styles when window keys are off
    bind -T root F12  \
        set prefix None \;\
        set key-table off \;\
        if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
        refresh-client -S \;\

    bind -T off F12 \
      set -u prefix \;\
      set -u key-table \;\
      refresh-client -S
  '';
  home.file.".tmux/renew_env.sh".source = ./tmux/renew_env.sh;
  home.file.".tmux/tmux.remote.conf".source = ./tmux/tmux.remote.conf;
  home.file.".tmux/status.conf".source = ./tmux/status.conf;

  home.stateVersion = "20.09";
}
