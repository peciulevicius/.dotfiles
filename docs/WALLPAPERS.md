# Wallpapers

This repo now includes a wallpapers folder:

- Directory: `~/.dotfiles/wallpapers`
- Set wallpaper script: `~/.dotfiles/scripts/wallpapers/set-wallpaper.sh`

## Commands

Set first wallpaper in folder:

```bash
scripts/wallpapers/set-wallpaper.sh
```

Set a specific wallpaper by filename:

```bash
scripts/wallpapers/set-wallpaper.sh astronaut2.png
```

Set a specific wallpaper by full path:

```bash
scripts/wallpapers/set-wallpaper.sh ~/Pictures/my-wallpaper.png
```

## Notes

- Script sets wallpaper for all current macOS desktops/spaces.
- If macOS asks for automation permissions for Terminal, allow it in System Settings.

