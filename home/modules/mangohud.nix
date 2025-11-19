{ ... }:
{
  programs.mangohud =
  {
    enable = true;
    settings =
    {
      # FPS
      fps = true;
      fps_limit = 117;

      # CPU
      cpu_temp = true;
      cpu_mhz = true;

      # GPU
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_mem_clock = true;
      gpu_power = true;

      # General
      no_display = true;
      background_alpha = 0;
    };
  };
}
