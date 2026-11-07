{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "repo";
  networking.networkmanager.enable = true;

  # Interfaz dedicada a la red de instalación de VMs nuevas (Red interna
  # de VirtualBox), con IP fija: enp0s8.
  networking.interfaces.enp0s8.ipv4.addresses = [{
    address = "192.168.100.1";
    prefixLength = 24;
  }];

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };
  console.keyMap = "es";

  users.users."adrianpr" = {
    isNormalUser = true;
    description = "Adrian Pastrian Ramiro";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "cambiame";
    packages = with pkgs; [ wget git fastfetch ];
  };

  services.openssh.enable = true;

  # ---------- DHCP + DNS ----------
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "enp0s8";
      bind-interfaces = true;
      dhcp-authoritative = true;
      dhcp-range = [ "192.168.100.100,192.168.100.200,255.255.255.0,12h" ];
      dhcp-option = [
        "option:router,192.168.100.1"
        "option:dns-server,192.168.100.1"   # las VMs nuevas usan esta VM como DNS
      ];
      # Nombres por hostname: en vez de una lista fija de MACs aquí (que
      # obligaría a nixos-rebuild cada vez que añades una VM), Ansible
      # rellena este fichero sobre la marcha y recarga dnsmasq — sin
      # tocar esta configuración para nada. Ver provision-new-vms.yml.
      domain = "lan";
      expand-hosts = true;
      addn-hosts = "/var/lib/dnsmasq/hosts.lan";
      # Sin "port = 0": así dnsmasq sí responde DNS (puerto 53), reenviando
      # lo que no sabe a estos servidores. Sin esto, las VMs nuevas no
      # pueden resolver github.com y el git clone de setupVM.sh falla.
      server = [ "1.1.1.1" "8.8.8.8" ];
      domain-needed = true;
      bogus-priv = true;
    };
  };
  networking.firewall.allowedUDPPorts = [ 67 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  # El fichero tiene que existir ya (aunque vacío) antes de que arranque
  # dnsmasq la primera vez; luego Ansible lo va rellenando.
  systemd.tmpfiles.rules = [
    "f /var/lib/dnsmasq/hosts.lan 0644 root root -"
  ];

  # Da salida a Internet a las VMs de la red interna (enp0s8) a través del
  # NAT de esta VM (enp0s3) — si no, setupVM.sh no puede hacer el git clone.
  networking.nat = {
    enable = true;
    externalInterface = "enp0s3";
    internalInterfaces = [ "enp0s8" ];
  };

  # ---------- Ansible ----------
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    wget
    git
    fastfetch
    ansible
    sshpass   # lo necesita Ansible para autenticar con ansible_ssh_pass
  ];

  system.stateVersion = "26.05";
}
