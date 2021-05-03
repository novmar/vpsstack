{ config, pkgs, lib, ... }:

let
    ks= "karluvsklep";
    ksdomain = "ks.marnov.cz";
    ksdatadir = "/var/lib/${ksdomain}";

in {
  imports = [
    ../../environments/base.nix
   <vpsadminos/os/lib/nixos-container/vpsadminos.nix>

  ];

  # ... standard NixOS configuration ...

     networking.hostName = "playnew";
     services.nginx.enable= true;
     services.nginx.virtualHosts.${ksdomain} = {
            extraConfig = ''
               if ($request_uri ~* "^(.*/)index\.php/(.*)") {
                return 307 $1$2;
                }
            '';
            root = "${ksdatadir}/www";
            locations."/".tryFiles = "$uri /index.php?$query_string";
            locations."~* \\.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\\.php)?|xtmpl|yml)(~|\\.sw[op]|\\.bak|\\.orig|\\.save)?$|/(\\.(?!well-known).*|Entries.*|Repository|Root|Tag|Template|composer\\.(json|lock)|web\\.config)$|/#.*#$|\\.php(~|\\.sw[op]|\\.bak|\\.orig|\\.save)$" = {
                return = "404";
                extraConfig = ''
                deny all;
                '';
            };


            locations."= /favicon.ico".extraConfig = ''
                log_not_found off;
                access_log off;
            '';
            locations."= /robots.txt".extraConfig = ''
                    allow all;
                    log_not_found off;
                    access_log off;
            '';
            locations."~* \\.(txt|log)$".extraConfig = ''
                    allow 192.168.0.0/16;
                    deny all;
            '';
            locations."~ \\..*/.*\\.php$".return = "403";
            locations."~ ^/sites/.*/private/".return = "403";
            locations."~ ^/sites/[^/]+/files/.*\\.php$".extraConfig = ''
                    deny all;
            '';
            locations."~* ^/.well-known/".extraConfig = ''
                    allow all;
            '';
            locations."~ (^|/)\\.".return = "403";
            locations."@rewrite".extraConfig = ''
                   rewrite ^ /index.php;
                   '';
            locations."~ /vendor/.*\\.php$" = {
                return = "404";
                extraConfig = ''
                      deny all;
                      '';
                };
            locations."~ '\\.php$|^/update.php'".extraConfig = ''
                fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
                try_files $fastcgi_script_name =404;

                include ${pkgs.nginx}/conf/fastcgi_params;
                include ${pkgs.nginx}/conf/fastcgi.conf;

                fastcgi_param HTTP_PROXY "";
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
                fastcgi_param QUERY_STRING $query_string;
                fastcgi_intercept_errors on;
                fastcgi_pass unix:${config.services.phpfpm.pools.${ks}.socket};
                '';
             locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$" = {
                 tryFiles = "$uri @rewrite";
                 extraConfig = ''
                    expires max;
                    log_not_found off;
                 '';
             };
             locations."~ ^/sites/.*/files/styles/".tryFiles = "$uri @rewrite";
             locations."~ ^(/[a-z\\-]+)?/system/files/".tryFiles = "$uri /index.php?$query_string";


            };
             services.phpfpm.pools.${ks} = {
              user = ks;
              settings = {
                "listen.owner" = config.services.nginx.user;
                "pm" = "dynamic";
                "pm.max_children" = 32;
                "pm.max_requests" = 500;
                "pm.start_servers" = 2;
                "pm.min_spare_servers" = 2;
                "pm.max_spare_servers" = 5;
                "php_admin_value[error_log]" = "stderr";
                "php_admin_flag[log_errors]" = true;
                "catch_workers_output" = true;
              };
              phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
            };
            users.users.${ks} = {
                isSystemUser = true;
                createHome = true;
                home = ksdatadir;
                group  = ks;
            };
            users.groups.${ks} = {};


networking.firewall.allowedTCPPorts = [ 80 443 ] ;
}
