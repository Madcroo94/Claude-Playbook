Claude Playbook toolbox
=======================

This folder (C:\Windows\ClaudePlaybook) was added by the Claude Playbook.
Double-click a .cmd file to run it. Each one asks for administrator rights,
shows what it does and writes a log to the Logs folder.

Restore Windows settings (undo all).cmd
    Puts back every Windows setting, service and scheduled task the
    playbook changed, using the backup taken before it changed anything
    (Backup\state.json). Removed apps are allowed to come back, but are not
    reinstalled: use the Apps folder for that. Restart afterwards.

Undo one change\
    The same, for one option at a time.

Apps\
    Install or remove Edge and OneDrive, reinstall the Xbox apps, Game Bar,
    Copilot and Phone Link from the Microsoft Store, and install Brave or
    Firefox. Other removed apps (Bing News, Clipchamp, Solitaire, ...) can be
    installed again from the Microsoft Store after running
    "Allow removed apps to come back".

Gaming\
    Turn the gaming power plan on or off.

Developer\
    Turn the WSL 2 features on or off. After turning them on and
    restarting, run "wsl --install" to add a Linux distribution.

Good to know
    - Defender: if you turned it off, run the playbook again in AME Wizard
      and choose "Keep Defender on". Windows protects these settings, so the
      toolbox alone may not be able to switch them back.
    - Running the playbook again with an option turned off undoes that
      option, unless you changed the setting yourself in the meantime.
    - The "python" Store shortcuts come back from Settings > Apps >
      Advanced app settings > App execution aliases.
    - Browsers the playbook installed are normal programs: uninstall them
      from Settings > Apps.
    - Do not delete the Backup folder. Without it, nothing can be restored.
