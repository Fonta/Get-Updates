# Get-Updates

## About

This script is used to download the latest updates from the Microsoft Updates Catalog. These downloaded updates can then be imported into MDT or applied directly to a WIM, to speed up the installation process of a machine.

Repo: <https://github.com/fonta/Get-Updates>

## Usage

Simply create JSON files for each OS you'd like to download updates for in the OSConfigs folder and run the script.
In the JSON file you'll have to configure the name and version of the OS, together with the location where the updates should be downloaded.
If you don't configure one of the 4 paths, the script will skip this type of update.

Here's an example json file for Windows Server 2019:

```json
{
    "Name" : "Windows Server 2019",
    "Version" : "1809",
    "StackUpdatePath" : "C:\\Temp\\W2K19\\Stack",
    "CumulativeUpdatePath" : "C:\\Temp\\W2K19\\Cumulative",
    "AdditionalUpdatesPath": "C:\\Temp\\W2K19\\Additional",
    "AdditionalUpdates" : [
        ".NET Framework 3.5 and 4.7.2",
        "Adobe Flash Player"
    ]
}
```

If you already downloaded the updates, but for some reason would like to download them again and overwrite the existing files, start the script with the `-Force` parameter.

## Proxy Usage

If you'd like to use a proxy, rename the `Config.json.example` to `Config.json` and configure the ProxyUrl and ProxyPort.
After that, start the script with the `-UseProxy` parameter.

## Logging

Logs will be written to a folder named "Logs" in the root folder of the script.

## Requirements

This script uses the LatestUpdate module made by Aaron Parker. Make sure you install this module, or include it in the Modules folder of this script.

- <https://github.com/aaronparker/LatestUpdate>
- <https://www.powershellgallery.com/packages/latestupdate>

## Screenshot

![Screenshot](https://i.imgur.com/BIZU6CS.png)
