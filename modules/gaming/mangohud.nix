{ username, ... }:
{
  home-manager.users.${username} =
  {
    programs.mangohud =
    {
      enable = true;
      settings =
      {
        fps = true;
        fps_limit = 141;

        cpu_temp = true;
        cpu_mhz = true;
        cpu_power = true;

        gpu_temp = true;
        gpu_core_clock = true;
        gpu_mem_clock = true;
        gpu_power = true;

        no_display = true;
        background_alpha = 0;
        winesync = true;
      };
    };

    home.sessionVariables =
    {
      MANGOHUD = "1";
    };
  };
}
