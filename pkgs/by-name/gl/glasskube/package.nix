{ lib
, buildGoModule
, buildNpmPackage
, fetchFromGitHub
, nix-update-script
, installShellFiles
}:

let
  version = "0.14.0";
  gitSrc = fetchFromGitHub {
    owner = "glasskube";
    repo = "glasskube";
    rev = "refs/tags/v${version}";
    hash = "sha256-k2PjdPPRPOZBr5AUGR25LJVN4/4jWaeTEX2ILLA3o10=";
  };
  web-bundle = buildNpmPackage rec {
    inherit version;
    pname = "glasskube-web-bundle";

    src = gitSrc;

    npmDepsHash = "sha256-0PzjOOdKkKjKUsi+uWYkGAyEXynMNq2OODH/sX2SsWQ=";

    dontNpmInstall = true;

    installPhase = ''
      runHook preInstall

      mkdir $out
      mv internal/web/root/static/bundle $out

      runHook postInstall
    '';
  };

in buildGoModule rec {
  inherit version;
  pname = "glasskube";

  src = gitSrc;

  vendorHash = "sha256-030lHyj3kkcz56S75l2wM3sVxTch7j9sKqUlkebStFo=";

  CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/glasskube/glasskube/internal/config.Version=${version}"
    "-X github.com/glasskube/glasskube/internal/config.Commit=${src.rev}"
  ];

  subPackages = [ "cmd/${pname}" "cmd/package-operator" ];

  nativeBuildInputs = [ installShellFiles ];

  preBuild = ''
    cp -r ${web-bundle}/bundle internal/web/root/static/bundle
  '';

  postInstall = ''
    # Completions
    installShellCompletion --cmd glasskube \
      --bash <($out/bin/glasskube completion bash) \
      --fish <($out/bin/glasskube completion fish) \
      --zsh <($out/bin/glasskube completion zsh)
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description =
      "The missing Package Manager for Kubernetes featuring a GUI and a CLI";
    homepage = "https://github.com/glasskube/glasskube";
    changelog =
      "https://github.com/glasskube/glasskube/releases/tag/v${version}";
    maintainers = with maintainers; [ jakuzure ];
    license = licenses.asl20;
    mainProgram = "glasskube";
  };
}
