{ config, pkgs, lib, ... }:
{
  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = "/srv/authelia/jwt-secret";
      sessionSecretFile = "/srv/authelia/session-secret";
      storageEncryptionKeyFile = "/srv/authelia/storage-key";
      oidcHmacSecretFile = "/srv/authelia/oidc-hmac-secret";
      oidcIssuerPrivateKeyFile = "/srv/authelia/private.pem";
    };

    settings = {
      theme = "dark";
      log.level = "info";

      server.address = "tcp://127.0.0.1:9091";

      totp.issuer = "auth.archongrid.xyz";

      authentication_backend.file.path = "/srv/authelia/users.yml";

      session.cookies = [{
        domain = "archongrid.xyz";
        authelia_url = "https://auth.archongrid.xyz";
        default_redirection_url = "https://cloud.archongrid.xyz";
      }];

      regulation = {
        max_retries = 3;
        find_time = "2m";
        ban_time = "10m";
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "*.archongrid.xyz";
            policy = "one_factor";
          }
          {
            domain = "cloud.archongrid.xyz";
            policy = "bypass";
             resources = [
              "^/remote\\.php/dav(/.*)?$"
              "^/remote\\.php/webdav(/.*)?$"
              "^/\\.well-known/(carddav|caldav)$"
              "^/(status\\.php|ocs/v[12]\\.php/.*)$"
              "^/public\\.php/.*$"
            ];
          }
          
        ];
      };

      identity_providers.oidc.clients = [
        {
          client_id = "nextcloud";
          client_name = "Nextcloud";
          client_secret = "$pbkdf2-sha512$310000$FpxtWraRqjCRgaSNcXiAvg$BqlA0TzGGQrLbgqvniUYEhf0O21jDr9C.Ma2x3dVFXa0jdlyJqK5uZQvNJ9KtGsRUvY9p6eYDF.S19xmMe4DXg";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [ "https://cloud.archongrid.xyz/apps/user_oidc/code" ];
          scopes = [ "openid" "profile" "email" "groups" ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          client_id = "jellyfin";
          client_name = "Jellyfin";
          client_secret = "$pbkdf2-sha512$310000$Kek7Tm7JkELx.6uoToCuzg$gIMByTa6Bi/DYdcbhFe6PWX/jMFrvdjSbmCoIbF9/9UKvPLfBrGFDCCtXv71eql4g58Bb1ChL6PKfZem2Bdm4Q";
          public = false;
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://jellyfin.archongrid.xyz/sso/OID/redirect/authelia" ];
          scopes = [ "openid" "profile" "groups" ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }

      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/authelia 0750 authelia-main authelia-main -"
  ];

  ## Caddy
  services.caddy.virtualHosts."auth.archongrid.xyz".extraConfig = ''
    reverse_proxy 127.0.0.1:9091
  '';

  # gate non-OIDC app behind the portal. add inside vhost
  #   forward_auth 127.0.0.1:9091 {
  #     uri /api/authz/forward-auth
  #     copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
  #   }
}
