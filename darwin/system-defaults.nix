{ ... }:

{
  system.defaults = {
    # =========================================================================
    # NSGlobalDomain (General UI/UX)
    # =========================================================================
    NSGlobalDomain = {
      # Expand save/print panels by default
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;

      # Disable automatic text features
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # Disable automatic termination of inactive apps
      NSDisableAutomaticTermination = true;

      # Keyboard settings
      AppleKeyboardUIMode = 3;       # Full keyboard access
      KeyRepeat = 2;                 # Fast repeat
      InitialKeyRepeat = 15;         # Short delay before repeat
      ApplePressAndHoldEnabled = false;  # Enable key repeat instead of accents

      # Trackpad settings
      "com.apple.trackpad.scaling" = 2.5;
      "com.apple.swipescrolldirection" = true;  # Natural scrolling
      "com.apple.mouse.tapBehavior" = 1;        # Tap to click

      # Show all file extensions
      AppleShowAllExtensions = true;
    };

    # =========================================================================
    # Trackpad
    # =========================================================================
    trackpad = {
      Clicking = true;                # Tap to click
      TrackpadThreeFingerDrag = true; # Three finger drag
    };

    # =========================================================================
    # Dock
    # =========================================================================
    dock = {
      tilesize = 48;
      magnification = false;
      minimize-to-application = true;
      show-process-indicators = true;
      launchanim = false;
      expose-animation-duration = 0.1;
      mru-spaces = false;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.3;
      autohide = true;
      show-recents = false;

      # Clear all default apps from dock
      persistent-apps = [];
      persistent-others = [];
    };

    # =========================================================================
    # Finder
    # =========================================================================
    finder = {
      AppleShowAllFiles = true;           # Show hidden files
      AppleShowAllExtensions = true;      # Show all extensions
      ShowStatusBar = true;
      ShowPathbar = true;
      _FXShowPosixPathInTitle = true;     # Full path in title
      _FXSortFoldersFirst = true;         # Folders on top
      FXDefaultSearchScope = "SCcf";      # Search current folder
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";      # Column view
    };

    # =========================================================================
    # Screenshots
    # =========================================================================
    screencapture = {
      location = "~/Desktop";
      type = "png";
      disable-shadow = true;
    };

    # =========================================================================
    # Screensaver
    # =========================================================================
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    # =========================================================================
    # Menu Bar Clock
    # =========================================================================
    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 1;
      ShowDayOfWeek = true;
      ShowSeconds = false;
    };

    # =========================================================================
    # Control Center
    # =========================================================================
    controlcenter = {
      BatteryShowPercentage = true;
      Bluetooth = true;
      Sound = true;
      AirDrop = false;
      Display = false;
      FocusModes = false;
      NowPlaying = false;
    };

    # =========================================================================
    # Activity Monitor
    # =========================================================================
    ActivityMonitor = {
      OpenMainWindow = true;
      IconType = 5;           # CPU usage in dock icon
      ShowCategory = 0;       # All processes
      SortColumn = "CPUUsage";
      SortDirection = 0;      # Descending
    };

    # =========================================================================
    # Software Update
    # =========================================================================
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = true;
    };

    # =========================================================================
    # Custom User Preferences (for settings not directly in nix-darwin)
    # =========================================================================
    CustomUserPreferences = {
      # Disable app quarantine dialog
      "com.apple.LaunchServices" = {
        LSQuarantine = false;
      };

      # Printer settings
      "com.apple.print.PrintingPrefs" = {
        "Quit When Finished" = true;
      };

      # Desktop services - avoid .DS_Store on network/USB
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      # Finder info panes
      "com.apple.finder" = {
        FXInfoPanesExpanded = {
          General = true;
          OpenWith = true;
          Privileges = true;
        };
      };

      # Safari settings
      "com.apple.Safari" = {
        UniversalSearchEnabled = false;
        SuppressSearchSuggestions = true;
        ShowFullURLInSmartSearchField = true;
        IncludeDevelopMenu = true;
        WebKitDeveloperExtrasEnabledPreferenceKey = true;
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
        SendDoNotTrackHTTPHeader = true;
      };

      # Time Machine
      "com.apple.TimeMachine" = {
        DoNotOfferNewDisksForBackup = true;
      };

      # TextEdit - plain text mode
      "com.apple.TextEdit" = {
        RichText = 0;
        PlainTextEncoding = 4;
        PlainTextEncodingForWrite = 4;
      };

      # Photos - prevent auto-open
      "com.apple.ImageCapture" = {
        disableHotPlug = true;
      };

      # Menu bar battery
      "com.apple.menuextra.battery" = {
        ShowPercent = "YES";
      };

      # Menu bar clock format
      "com.apple.menuextra.clock" = {
        DateFormat = "EEE d MMM HH:mm";
      };
    };

    CustomSystemPreferences = {
      # Software update settings
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 1;
        CriticalUpdateInstall = 1;
      };

      # App Store auto-update
      "com.apple.commerce" = {
        AutoUpdate = true;
      };
    };
  };

  # Disable boot sound
  system.nvram.variables = {
    SystemAudioVolume = " ";
  };

  # Activation scripts for settings that can't be declaratively managed
  system.activationScripts.postUserActivation.text = ''
    # Show ~/Library folder
    chflags nohidden ~/Library 2>/dev/null || true

    # Show /Volumes folder
    sudo chflags nohidden /Volumes 2>/dev/null || true

    # Hide Spotlight from menu bar (using Raycast instead)
    defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1 2>/dev/null || true

    # Disable Spotlight keyboard shortcut (Cmd+Space)
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" \
      ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true

    # Add login items
    add_login_item() {
      local app_path="$1"
      if [[ -d "$app_path" ]]; then
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}" 2>/dev/null || true
      fi
    }

    add_login_item "/Applications/Raycast.app"
    add_login_item "/Applications/AeroSpace.app"
    add_login_item "/Applications/MonitorControl.app"

    # Restart affected apps
    killall Dock Finder SystemUIServer 2>/dev/null || true
  '';
}
