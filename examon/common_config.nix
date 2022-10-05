{ pkgs, nur }:
{
  #imports = [ nur.repos.kapack.modules.examon ];

  environment.systemPackages = [ pkgs.nano pkgs.nur.repos.kapack.npb
                                 pkgs.openmpi ];

  environment.variables.EXAMON_INSTALL_PATH = "${pkgs.nur.repos.kapack.examon}";
    
  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";

  users.users.user1 = { isNormalUser = true; };
  users.users.user2 = { isNormalUser = true; };

  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ]; 
}
