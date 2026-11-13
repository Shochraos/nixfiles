{ inputs, den, ... }:
{
  den.aspects.discord = {
    includes = [
      (den.batteries.unfree [
        "discord"
        "discord-unwrapped"
      ])
    ];
    provides.to-users.homeManager =
      {
        config,
        pkgs,
        osConfig,
        ...
      }:
      {
        imports = [ inputs.nixcord.homeModules.nixcord ];
        programs.nixcord = {
          enable = true;
          discord = {
            package = pkgs.discord // {
              override = args: pkgs.discord.override (removeAttrs args [ "branch" ]);
            };
            equicord.enable = true;
            openASAR.enable = false;
          };
          config = {
            useQuickCss = true;
            frameless = true;
            enabledThemes = [
              "stylix.theme.css"
              "matugen.css"
            ];
            plugins = {
              alwaysTrust.enable = true;
              betterBackreading.enable = true;
              betterForwards.enable = true;
              betterImageEditor.enable = true;
              betterMutualServers.enable = true;
              bypassPinPrompt.enable = true;
              characterCounter.enable = true;
              clearUrls.enable = true;
              concatenatedModules.enable = true;
              crashHandler.enable = true;
              declutter.enable = true;
              directFileDownload.enable = true;
              dontRoundMyTimestamps.enable = true;
              equiTweaks.enable = true;
              expressionManager.enable = true;
              fakeNitro.enable = true;
              fastDeleteChannels.enable = true;
              fixImagesQuality.enable = true;
              fixSpotifyEmbeds.enable = true;
              fixYoutubeEmbeds.enable = true;
              forceOwnerCrown.enable = true;
              fullVcpfp.enable = true;
              homeTyping.enable = true;
              jumpTo.enable = true;
              mentionAvatars.enable = true;
              messageLogger.enable = true;
              messageLoggerEnhanced.enable = true;
              musicControls.enable = true;
              neverPausePreviews.enable = true;
              newGuildSettings.enable = true;
              newPluginsManager.enable = true;
              noBlockedMessages.enable = true;
              noMiddleClickPaste.enable = true;
              noNitroUpsell.enable = true;
              noOnboardingDelay.enable = true;
              noSystemBadge.enable = true;
              notificationTitle.enable = true;
              onePingPerDm.enable = true;
              openInApp.enable = true;
              permissionsViewer.enable = true;
              previewMessage.enable = true;
              questify.enable = true;
              relationshipNotifier.enable = true;
              shikiCodeblocks.enable = true;
              showTimeoutDuration.enable = true;
              splitLargeMessages.enable = true;
              translate.enable = true;
              translatePlus.enable = true;
              userPfp.enable = true;
              usrbg.enable = true;
              validReply.enable = true;
              validUser.enable = true;
              viewIcons.enable = true;
              voiceChatDoubleClick.enable = true;
              voiceMessages.enable = true;
              volumeBooster.enable = true;
              whoReacted.enable = true;
              whosWatching.enable = true;
              writeUpperCase.enable = true;
              youtubeAdblock.enable = true;
              zipPreview.enable = true;
            };
          };
          extraConfig.plugins = {
            "fakeNitro" = {
              "transformEmojis" = false;
              "transformStickers" = false;
            };
            "fastDeleteChannels" = {
              "reqShift" = false;
            };
            "messageLogger" = {
              "ignoreBots" = false;
            };
            "messageLoggerEnhanced" = {
              "cacheLimit" = 0;
              "cacheMessagesFromServers" = true;
              "ignoreBots" = true;
              "ignoreSelf" = true;
              "ignoreWebhooks" = true;
              "imageCacheDir" = "/home/shochraos/.config/Equicord/MessageLoggerData/images";
              "logsDir" = "/home/shochraos/.config/Equicord/MessageLoggerData/logs";
              "messageLimit" = 0;
              "saveImages" = true;
            };
            "musicControls" = {
              "showSpotifyControls" = true;
            };
            "newGuildSettings" = {
              "messages" = 1;
            };
            "questify" = {
              "acknowledgedNotices" = {
                "quest-ban-warning-2026-08-07" = true;
                "quest-ban-warning-2026-08-26" = true;
              };
              "disableQuestsEverything" = true;
              "questButtonBadgeCount" = 15;
            };
            "shikiCodeblocks" = {
              "theme" =
                "https://cdn.jsdelivr.net/gh/shikijs/textmate-grammars-themes@bc5436518111d87ea58eb56d97b3f9bec30e6b83/packages/tm-themes/themes/one-dark-pro.json";
            };
            "translate" = {
              "dismissedAutoTranslateAlert" = true;
              "sentOutput" = "ja";
            };
            "usrbg" = {
              "nitroFirst" = false;
            };
          };
        };
        xdg.autostart.entries =
          if builtins.elem "discord" osConfig.host.autostart then
            [ "${config.programs.nixcord.finalPackage.discord}/share/applications/discord.desktop" ]
          else
            [ ];
      };
  };
}
