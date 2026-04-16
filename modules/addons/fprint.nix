{ ... }:
{
  services.fprintd.enable = true;
  security.pam.services = {
    login.fprintAuth = false;
    greetd.fprintAuth = false;
  };
}
