{ pkgs, modulesPath, nur, helpers, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs modulesPath nur; };
      fileSystemsNFSShared = {
        device = "server:/";
        fsType = "nfs";
      };

      node = { ... }: {
        imports = [ commonConfig ];
        fileSystems."/users" = fileSystemsNFSShared;
        services.oar.node.enable = true;
      };
    in {
      frontend = { ... }: {
        imports = [ commonConfig ];
        fileSystems."/users" = fileSystemsNFSShared;
        services.oar.client.enable = true;
      };

      server = { ... }: {
        imports = [ commonConfig ];
        services.oar.server.enable = true;
        services.oar.dbserver.enable = true;
        # NFS shared users' home
        services.nfs.server.enable = true;
        services.nfs.server.exports = ''
          /users *(rw,no_subtree_check,fsid=0,no_root_squash)
        '';
        nxc.postBootCommands = "mkdir -p /users && chmod 777 /users";

      };
    } // helpers.makeMany node "node" 2;

  testScript = ''
    frontend.succeed("true")
  '';
}
