{ pkgs, modulesPath, nur }: {
  environment.variables.MELISSA_SRC = "${pkgs.nur.repos.kapack.melissa-launcher.src}";
  environment.systemPackages = [
    pkgs.nur.repos.kapack.melissa-heat-pde
    pkgs.nur.repos.kapack.melissa-launcher
  ];
}