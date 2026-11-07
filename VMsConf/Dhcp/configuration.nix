{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "repo";
  networking.networkmanager.enable = true;

  # Interfaz dedicada a la red de instalación de VMs nuevas, con IP fija
  networking.interfaces.eth1.ipv4.addresses = [{
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
      interface = "eth1";
      bind-interfaces = true;
      dhcp-authoritative = true;
      dhcp-range = [ "192.168.100.100,192.168.100.200,255.255.255.0,12h" ];
      dhcp-option = [
        "option:router,192.168.100.1"
        "option:dns-server,192.168.100.1"   # las VMs nuevas usan esta VM como DNS
      ];
      # Sin "port = 0": así dnsmasq sí responde DNS (puerto 53), reenviando lo que no sabe a estos servidores
      server = [ "1.1.1.1" "8.8.8.8" ];
      domain-needed = true;
      bogus-priv = true;
    };
  };
  networking.firewall.allowedUDPPorts = [ 67 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ "eth1" ];
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
