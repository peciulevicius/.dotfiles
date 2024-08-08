# Windows terminal customization

**Links**
Based on this tutorial: https://www.youtube.com/watch?v=-G6GbXGo4wo&ab_channel=TroubleChute

Windows Terminal themes: https://windowsterminalthemes.dev/

Nerd Fonts: https://github.com/ryanoasis/nerd-fonts/

Oh My Posh: https://ohmyposh.dev/

## Settings
- **Appearance**: Use acrylic material for background: `true` to make the top transparent.

## Color Schemes
1. Visit [windowsterminalthemes.dev](https://windowsterminalthemes.dev/).
2. Choose a theme and click "Get theme".
3. Copy the JSON to the terminal `settings.json` file.

Example `settings.json`:
```json
{
    "schemes": [
        {
            "name": "BlulocoDark",
            "black": "#41444d",
            "red": "#fc2f52",
            "green": "#25a45c",
            "yellow": "#ff936a",
            "blue": "#3476ff",
            "purple": "#7a82da",
            "cyan": "#4483aa",
            "white": "#cdd4e0",
            "brightBlack": "#8f9aae",
            "brightRed": "#ff6480",
            "brightGreen": "#3fc56b",
            "brightYellow": "#f9c859",
            "brightBlue": "#10b1fe",
            "brightPurple": "#ff78f8",
            "brightCyan": "#5fb9bc",
            "brightWhite": "#ffffff",
            "background": "#282c34",
            "foreground": "#b9c0cb",
            "selectionBackground": "#b9c0ca",
            "cursorColor": "#ffcc00"
        }
    ],
    "themes": []
}

```

## Nerd Fonts
1. Visit [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/).
2. Download the font of your choice (e.g., Fira Code Nerd Font).
3. Extract and install the fonts by selecting all of them, right clicking and clicking install.
4. Restart the terminal.
5. Go to `Settings > Profiles > Defaults > Text` and select the installed font.

## Oh My Posh

> [!NOTE]  
> Make sure you have access to the `winget` command. You can check by running `winget --version` in the terminal.
> If you don't have access to the `winget` command, you can install `App Installer` it in the Microsoft Store.

1. Ensure you have access to the `winget` command (`winget --version`).
2. If not, install `App Installer` from the Microsoft Store.
3. Follow the installation instructions on [Oh My Posh](https://ohmyposh.dev/docs/installation/windows).
4. Restart the terminal and verify installation with `oh-my-posh --version`.

### Default themes

You can find the themes in the folder indicated by the environment variable `POSH_THEMES_PATH`. For example, 
you can use `oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kali.omp.json" | Invoke-Expression` for the 
prompt initialization in PowerShell. This will enable default setup, things in the terminal will look a little bit different.

Now we can customize our theme running `Get-PoshThemes` to see the available themes. To change your theme, adjust the 
init script in `C:\Users\Name\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

For example:
```powershell Microsoft.PowerShell_profile.ps1
  oh-my-posh init pwsh --config 'C:\Users\Name\AppData\Local\Programs\oh-my-posh\themes\kali.omp.json' | Invoke-Expression
```

Make settings permanent by following [this guide](https://ohmyposh.dev/docs/installation/prompt).

This guide is for PowerShell, but you can follow the Oh My Posh guide to set it up for other shells as well.
