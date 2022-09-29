{ pkgs, nur }:
{
  #imports = [ nur.repos.kapack.modules.bdpo ];

  environment.systemPackages = [
    pkgs.nano pkgs.cpufrequtils
    pkgs.nur.repos.kapack.bdpo
    pkgs.python3
    #pkgs.nur.repos.kapack.npb
    #pkgs.openmpi
  ];

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";

  users.users.user1 = { isNormalUser = true; };
  users.users.user2 = { isNormalUser = true; };
  
  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "*"; item = "stack"; type = "-"; value = "unlimited"; }
  ]; 
}