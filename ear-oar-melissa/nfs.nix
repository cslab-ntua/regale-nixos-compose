{ flavour, ...}:
let
  nfsDockerServer = {
    fileSystems = {
      "/srv/shared" = {
        device = "/fakefs";
        options = [ "bind" ];
      };
    };
  };
  nfsDockerClient = {
    fileSystems = {
      "/srv/shared" = {
        device = "/fakefs";
        options = [ "bind" ];
      };
    };
  };
  nfsServer = {
    services.nfs.server.enable = true;
    services.nfs.server.exports =
      "/srv/shared *(rw,no_subtree_check,fsid=0,no_root_squash)";
    services.nfs.server.createMountPoints = true;
  };
  nfsClient = {
    fileSystems = {
      "/data" = {
        device = "server:/";
        fsType = "nfs";
      };
    };
  };
in {
  server = if flavour.name == "docker" then nfsDockerServer else nfsServer;
  client = if flavour.name == "docker" then nfsDockerClient else nfsClient;
}
