# Downloaders: gluetun (ProtonVPN) -> qbittorrent, plus sabnzbd.
# qBittorrent shares gluetun's network namespace, so it has no network
# path except the tunnel — gluetun's internal firewall is the kill switch.
#
# UIs are bound to loopback only and exposed to the tailnet via
# `tailscale serve` — nothing is reachable from LAN or the internet.
{ config, pkgs, ... }:

{
  ###### shared media user/group (PUID/PGID for linuxserver images) ######
  users.groups.media.gid = 2000;
  users.users.media = {
    isSystemUser = true;
    uid = 2000;
    group = "media";
  };

  ###### config dirs + download tree ######
  systemd.tmpfiles.rules = [
    "d /var/lib/gluetun            0700 root  root  -"
    "d /var/lib/qbittorrent        0750 media media -"
    "d /var/lib/sabnzbd            0750 media media -"
    "d /scratch/downloads          0775 root  media -"
    "d /scratch/downloads/torrents 2775 media media -"
    "d /scratch/downloads/usenet   2775 media media -"
  ];

  virtualisation.podman.enable = true;

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {

      gluetun = {
        image = "qmcgaw/gluetun:v3";
        environment = {
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          SERVER_COUNTRIES = "United States";
          SERVER_CITIES = "Los Angeles";     # pick something close-ish with P2P servers
          VPN_PORT_FORWARDING = "on";
          PORT_FORWARD_ONLY = "on";              # only connect to servers that support NAT-PMP PF
          # Push the forwarded port into qBittorrent whenever Proton rotates it.
          # Requires "bypass auth for localhost" in the qbit WebUI settings.
          # ({{PORTS}} on gluetun >= 3.39; older versions use {{PORT}})
          VPN_PORT_FORWARDING_UP_COMMAND = ''/bin/sh -c 'wget -O- --retry-connrefused --post-data "json={\"listen_port\":{{PORTS}}}" http://127.0.0.1:8080/api/v2/app/setPreferences' '';
          FIREWALL_INPUT_PORTS = "8080";         # allow the published-port traffic through gluetun's firewall
          TZ = "America/Los_Angeles";
        };
        # Contains: WIREGUARD_PRIVATE_KEY=...   (kept out of the nix store)
        environmentFiles = [ "/var/lib/gluetun/secrets.env" ];
        # qbit's webui is published HERE because qbit lives in this netns.
        # Loopback-only: reachable via tailscale serve, nothing else.
        ports = [ "127.0.0.1:8080:8080" ];
        volumes = [ "/var/lib/gluetun:/gluetun" ];
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun"
        ];
      };

      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        dependsOn = [ "gluetun" ];
        environment = {
          PUID = "2000";
          PGID = "2000";
          TZ = "America/Los_Angeles";
          WEBUI_PORT = "8080";
        };
        volumes = [
          "/var/lib/qbittorrent:/config"
          "/scratch/downloads/torrents:/downloads"
        ];
        extraOptions = [ "--network=container:gluetun" ];
      };

      sabnzbd = {
        image = "lscr.io/linuxserver/sabnzbd:latest";
        environment = {
          PUID = "2000";
          PGID = "2000";
          TZ = "America/Los_Angeles";
        };
        ports = [ "127.0.0.1:8085:8080" ];
        volumes = [
          "/var/lib/sabnzbd:/config"
          "/scratch/downloads/usenet:/downloads"
        ];
      };

    };
  };

  # If gluetun restarts, its network namespace is destroyed and qbit is left
  # holding a dead netns — propagate the restart.
  systemd.services.podman-qbittorrent = {
    partOf = [ "podman-gluetun.service" ];
    after = [ "podman-gluetun.service" ];
  };

  ###### tailnet-only exposure ######
  services.tailscale.enable = true;

  # `tailscale serve --bg` persists its config in tailscaled state, so
  # re-running this on every boot/rebuild is idempotent.
  systemd.services.tailscale-serve-downloaders = {
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.tailscale}/bin/tailscale serve --bg --https=8443 http://127.0.0.1:8080
      ${pkgs.tailscale}/bin/tailscale serve --bg --https=8444 http://127.0.0.1:8085
    '';
  };

  # serve's listener is a host process on tailscale0, so this firewall
  # rule works normally (unlike podman-published ports, which DNAT past
  # the INPUT chain entirely — that's why loopback binding does the real
  # isolation above).
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8443 8444 ];
}
