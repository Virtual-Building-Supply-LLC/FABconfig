# Changelog

What changed in each version of FABconfig. Versions are dates (`vYY.MM.DD`); see [README.md](README.md#versions-and-releases).

## Unreleased

## v26.11.22

### Added
- **ESTmep or CAMduct Project Location (optional)** in Configuration details, with Browse. It's written to the map.ini as `[PROGRAM PATHS] Project=`. Left blank, projects stay in a `projects` folder inside the configuration location (`Project=./projects`, as before). The folder is created if it doesn't exist; it must be a full path and can't be in the database folder.

## v26.11.21.2

### Added
- **Help → How to use FABconfig**: a page with short steps for adding and removing configurations, and a button to the online instructions.
- **Help → Online instructions** opens the "How to use it" section of the README on GitHub in your web browser.

### Changed
- "What's this?" is no longer in the sidebar; it's under **Help** (and the "How it works…" button).

## v26.11.21.1

### Added
- **Remove Configurations** page (formerly the separate internal tool FABclean): lists every Fabrication configuration registered on this PC and removes the ones you tick, deleting their registry entries for every Fabrication version and, optionally, moving their folders to the Recycle Bin. Nothing is ticked for you; configurations FABconfig didn't make are labelled "Set up by hand", and you confirm before anything is removed. It never removes a drive or share root, a database folder, FABconfig's own folder, or a folder another configuration still uses.

### Changed
- Sidebar items are now **Add Configuration**, **Remove Configurations** and **What's this?**. The window is wider (1180 × 640) to fit them and the list.
- The window title is "FABconfig - Fabrication Configurations".
- In the dark theme the configuration list, its column titles, scroll bars and the File/Help menus are dark too.
- The compiled file is always named `FABconfig.exe`, without the version.

## v26.11.21

### Added
- Light and dark themes, switched with the button at the top right. FABconfig remembers the choice for each user (in `HKEY_CURRENT_USER\Software\Virtual Building Supply\FABconfig`).
- Before overwriting a configuration that already exists, FABconfig shows which Fabrication versions it's registered with and where it points, and warns if it wasn't made by FABconfig.
- An overwritten `map.ini` is kept as `map.ini.bak`.
- An overwrite also updates the configuration in any other Fabrication version it was registered with, not just the versions shown under "Registers with".

- README explains how to add a `[COMPANY-INFO]` `DBNAME` to a database's `map.ini`, so FABconfig can fill in the configuration name.
- The compiled `.exe` has the sidebar logo built in, so it no longer needs the `Resources` folder next to it.

### Changed
- New look matching MapQuery Studio: dark theme by default with a light theme, a blue accent, a sidebar with pill-shaped items and the "Registers with" versions, File and Help menus, an info banner and a status bar showing the database folder and version.
- New app icon (a folder with a plus, in the style of MapQuery Studio's icon) for the window, taskbar and `.exe`. The VBS logo is now shown on the What's this? page.
- The window is 20% wider, so long configuration and database paths fit.
- The configuration location can't be inside the database folder. (Tools that mirror the database, such as `robocopy /MIR`, would delete it.)
- A configuration folder (one whose `map.ini` points to a database somewhere else) is no longer accepted as a database folder.
- Only `map.ini` and `config.png` have their read-only flag cleared, instead of every file in the configuration folder.
- When the database's `map.ini` has no `[COMPANY-INFO]` `DBNAME`, the name starts blank but the location still starts at `C:\fabrication-configurations\` and follows the name as you type.
- The script is now always named `FABconfig.ahk`. The compiled file is named after the version, for example `FABconfig_v26.10.24.exe`.

## v26.10.24

First release.

- Registers a Fabrication database as a named configuration for Fabrication versions from four years before to two years after the current year.
- Creates the configuration folder, writes a `map.ini` that points to the shared database, and copies `config.png`.
- Fills in the configuration name from `DBNAME` in the database's `map.ini`.
- Asks for the database folder when FABconfig isn't run from one.
- "What's this?" page explaining each step.
