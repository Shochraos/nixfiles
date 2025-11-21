{ ... }:
{
  programs.plasma =
  {
    workspace =
    {
      enableMiddleClickPaste = false;

      lookAndFeel = "com.github.vinceliuice.Orchis-dark";
      theme = "Unity-Plasma";
      colorScheme = "MateriaDark";
      iconTheme = "Tela circle dark";
      soundTheme = "Ocean";
      wallpaperPictureOfTheDay.provider = "bing";
    };
  };
}