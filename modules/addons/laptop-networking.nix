{ ... }:
{
  environment.etc =
  {
    "ssl/certs/T-TeleSec_GlobalRoot_Class_2.pem".source = ../../assets/certs/T-TeleSec_GlobalRoot_Class_2.pem;
  };
  
  systemd.network.wait-online.enable = false;
}