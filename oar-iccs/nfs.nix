{ flavour, ... }:
let
  permission = {
    boot.postBootCommands = ''
      chown user1 users -R /tmp/shared
      chmod 777 -R /tmp/shared
    '';
  };
  permission_docker = {
    boot.postBootCommands = ''
      mkdir /var/nxc/shared/u1
      chown user1 users -R /var/nxc/shared/u1
      chmod 777 -R /var/nxc/shared/u1
    '';
  };
  nfsDockerServer = {
    imports = [ permission_docker ];
    fileSystems = {
      "/home/user1" = {
        device = "/var/nxc/shared/u1";
        options = [ "bind" ];
      };
    };
  };
  nfsDockerClient = {
    fileSystems = {
      "/home/user1" = {
        device = "/var/nxc/shared/u1";
        options = [ "bind" ];
      };
    };
  };
  nfsServer = {
    imports = [ permission ];
    services.nfs.server.enable = true;
    services.nfs.server.exports =
      "/home/user1 *(rw,no_subtree_check,fsid=0,no_root_squash)";
    services.nfs.server.createMountPoints = true;
  };
  nfsClient = {
    fileSystems = {
      "/home/user1" = {
        device = "server:/";
        fsType = "nfs";
      };
    };
  };
in {
  server = if flavour.name == "docker" then nfsDockerServer else nfsServer;
  client = if flavour.name == "docker" then nfsDockerClient else nfsClient;
}

