{ lib, isAzazel, ... }:
{
  programs.plasma =
  {
    input =
    {
      mice =
      []
      ++ lib.optionals isAzazel
      [
        {
          name = "Razer Razer Basilisk V3 Pro";
          vendorId = "1532";
          productId = "00ab";
          enable = true;
          acceleration = null;
          accelerationProfile = "none";
          scrollSpeed = 1;
          naturalScroll = false;
          middleButtonEmulation = false;
        }
        {
          name = "Keychron  Keychron Link ";
          vendorId = "3434";
          productId = "d030";
          enable = false;
        }
        {
          name = "Razer Razer Basilisk V3 Pro Keyboard";
          vendorId = "1532";
          productId = "00ab";
          enable = false;
        }
        {
          name = "Razer Razer Basilisk V3 Pro Mouse";
          vendorId = "1532";
          productId = "00ab";
          enable = false;
        }
      ];

      keyboard =
      {
        repeatDelay = 400;
        repeatRate = 40;
      };
    };
  };
}