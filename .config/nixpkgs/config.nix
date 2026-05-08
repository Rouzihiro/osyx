{
  # allow nonfree packages
  allowUnfree = true;

  # allow specific insecure packages if you must pin legacy shit
  permittedInsecurePackages = [
    # example:
    # "openssl-1.1.1w"
  ];

  # allow broken packages when you know what you're doing
  allowBroken = false;

  # cuda / gpu tooling toggle
  cudaSupport = false;

  # android / cross builds
  android_sdk.accept_license = true;

  # unfree packages whitelist (optional, tighter control)
  # allowUnfreePredicate = pkg:
  #   builtins.elem (builtins.parseDrvName pkg.name).name [
  #     "nvidia-x11"
  #     "steam"
  #     "steam-original"
  #     "steam-run"
  #   ];

  # package-level overrides hook
  packageOverrides = pkgs: {
    # example:
    # myNeovim = pkgs.neovim.override {
    #   configure = {
    #     customRC = "set number";
    #   };
    # };
  };
}

