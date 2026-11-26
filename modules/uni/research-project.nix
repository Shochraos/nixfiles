{
  den.aspects.research-project.nixos =
    { pkgs, ... }:
    let
      qwenModel = pkgs.fetchurl {
        url = "https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/a06e946bb6b655725eafa393f4a9745d460374c9/Qwen3-4B-Instruct-2507-Q4_K_M.gguf";
        hash = "sha256-NgWAO5gstkrq1E9sGyrjbjrNtB2ORsipTGUzvExn5Zc=";
      };
    in
    {
      services.llama-cpp = {
        enable = true;
        openFirewall = false;
        settings = {
          host = "127.0.0.1";
          port = 8081;
          model = toString qwenModel;
          alias = "qwen3-4b-instruct-2507";
          ctx-size = 8192;
          parallel = 1;
          temp = 0.7;
          top-p = 0.8;
          top-k = 20;
          min-p = 0;
          seed = 42;
        };
      };
    };
}
