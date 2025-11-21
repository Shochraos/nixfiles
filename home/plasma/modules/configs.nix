{ ... }:
{
  programs.plasma =
  {
    configFile =
    {
      "kdeglobals".General =
      {
        TerminalApplication = "ghostty";
      };
      "kdeglobals"."KFileDialog Settings" =
      {
        "Show hidden files" = false;
        "View Style" = "DetailTree";
      };
      "dolphinrc"."General" =
      {
        RememberOpenedTabs = false;
      };
      "dolphinrc"."DetailsMode" =
      {
        PreviewSize = 32;
      };
    };
  };
}