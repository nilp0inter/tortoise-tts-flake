{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/22.05;
    tortoise-tts = {
      type = "github";
      owner = "neonbjb";
      repo = "tortoise-tts";
      rev = "122d92d491896ca80cf5fbfe7c310ec761a2c0ca";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, tortoise-tts }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    python3 = pkgs.python3;
    python3Packages = pkgs.python3Packages;
    fetchurl = pkgs.fetchurl;
    rotary_embedding_torch = with python3Packages; buildPythonPackage rec {
      name = "rotary-embedding-torch";
      version = "0.1.5";
  
      src = pkgs.fetchFromGitHub {
        owner = "lucidrains";
        repo = "${name}";
        rev = "${version}";
        sha256 = "sha256-03elqCkEPL7Bt2vsjm7FYmv3wXMmwSnjrS3so/7LUuI=";
      };
  
      propagatedBuildInputs = with python3Packages; [
        torchaudio-bin
        einops
      ];
  
      doCheck = false;
      meta = {
        homepage = "https://github.com/lucidrains/rotary-embedding-torch";
        description = "Implementation of Rotary Embeddings, from the Roformer paper, in Pytorch";
      };
    };
    tortoise-models = {
      "autoregressive.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/301bf48/.models/autoregressive.pth";
        sha256 = "9c6651b9996df6cef6a1fc459738ae207ab60f902ec49b4d0623ca8ab6110d51";
      };
      "classifier.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/07a6edc/.models/classifier.pth";
        sha256 = "95ab946010be0a963b5039e8fca74bbb8a6eebcf366c761db21ae7e94cd6ada3";
      };
      "clvp2.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/3704aea/.models/clvp2.pth";
        sha256 = "6097e708cf692eb93bd770880660953935e87e8995eb864819bbe51b7d91342c";
      };
      "cvvp.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/301bf48/.models/cvvp.pth";
        sha256 = "d050e32592ad4a318e03a4f99b09c9c26baf68d78a9d7503ff2bc3883e897100";
      };
      "diffusion_decoder.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/301bf48/.models/diffusion_decoder.pth";
        sha256 = "ea776fc354eabb70cfae145777153483fad72e3e0c5ea345505ded2231a90ce1";
      };
      "vocoder.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/301bf48/.models/vocoder.pth";
        sha256 = "16e8153e9f8ffb00b116f7f67833df2802fcf81e6bc173acc3b3b4bf9f04189d";
      };
      "rlg_auto.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/7c18fdf/.models/rlg_auto.pth";
        sha256 = "4473c125482e2a3322a5ea762025a0c6ec657955c3002cf099c0635d79967551";
      };
      "rlg_diffuser.pth" = fetchurl {
        url = "https://huggingface.co/jbetker/tortoise-tts-v2/resolve/7c18fdf/.models/rlg_diffuser.pth";
        sha256 = "6e84b1ce60631c56dc8dec3d27c131993dd99d3060e7919cc351857457dbfdac";
      };
    };
    tortoise-models-dir = pkgs.runCommand "tortoise-models-dir" {} ''
      mkdir -p $out
      ln -sv ${tortoise-models."autoregressive.pth"} $out/autoregressive.pth
      ln -sv ${tortoise-models."classifier.pth"} $out/classifier.pth
      ln -sv ${tortoise-models."clvp2.pth"} $out/clvp2.pth
      ln -sv ${tortoise-models."cvvp.pth"} $out/cvvp.pth
      ln -sv ${tortoise-models."diffusion_decoder.pth"} $out/diffusion_decoder.pth
      ln -sv ${tortoise-models."vocoder.pth"} $out/vocoder.pth
      ln -sv ${tortoise-models."rlg_auto.pth"} $out/rlg_auto.pth
      ln -sv ${tortoise-models."rlg_diffuser.pth"} $out/rlg_diffuser.pth
    '';
  in {
    packages.x86_64-linux.tortoise-tts = python3Packages.buildPythonApplication rec {
      name = "tortoise-tts";
      version = "v2.4.2";
    
      src = tortoise-tts;
    
      postInstall = ''
        cp -Rvf tortoise/data $out/lib/${python3.executable}/site-packages/tortoise
        wrapProgram $out/bin/tortoise_tts.py --set TORTOISE_MODELS_DIR ${tortoise-models-dir}
      '';
    
      propagatedBuildInputs = with python3Packages; [
        tqdm
        rotary_embedding_torch
        inflect
        progressbar
        einops
        unidecode
        scipy
        librosa
        transformers
        tokenizers
        torchaudio-bin
      ];
      doCheck = false;
      patches = [
        ./models.patch
      ];
      meta = {
        homepage = "https://github.com/neonbjb/tortoise-tts";
        description = "A multi-voice TTS system trained with an emphasis on quality";
      };
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.tortoise-tts;

    apps.x86_64-linux.default = {
      type = "app";
      program = "${self.packages.x86_64-linux.tortoise-tts}/bin/tortoise_tts.py";
    };
  };
}

