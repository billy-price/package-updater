# Package-updater

## Installation
With [aftman](https://github.com/LPGhatguy/aftman) installed, run

```sh
aftman install
```

## Usage
```sh
# Give (Y/n) prompts for each package update
remodel run fullUpdate.lua

# Force all package updates with no prompts
remodel run fullUpdate.lua no_prompt
```

## Configuration

The first time you run
```sh
remodel run fullUpdate.lua
```

it will create a `config.lua` file with a few tables to fill out.
Consider this file the input arguments to the `fullUpdate.lua` program, which you
should check/modify each time you run.

Here you specify which packages to build, where to put them in the DataModel
and which places to update with these packages.

## How it works

These scripts make use of the remodel api, in particular
```lua
remodel.readPlaceAsset(assetId: string): Instance
remodel.readModelFile(path: string): List<Instance>
remodel.writeExistingAsset(instance: Instance, assetId: string)
Instance.new(className: string): Instance
<Instance>.Parent
<Instance>:FindFirstChild(name: string): Instance
<DataModel>:GetService(name: string): Instance
```
to download/load/modify/publish roblox place assets and model assets.
It uses `rojo build` to build the release version of each package.

The script `fullUpdate.lua` does the following
- Build all of the packages specified in `config.PackageProjectFiles` to `.rbxm` files using [rojo](https://github.com/rojo-rbx/rojo)
- For each place specified in `config.PlaceIds`...
	- Download the place asset using `remodel.readPlaceAsset`
	- For each of the built packages...
		- Find any existing packages of the same name in the corresponding destination (see `config.PackageDestination`)
		- Detect the versions of these packages
		- Prompt the user for confirmation to replace them with the newly built package
		- Replace existing packages with newly built package (using `<Instance>.Parent`)
	- Store change log for each package to Script instance called `PackageUpdateChangelog` and put in ServerStorage (replacing existing one if it's there)

To modify or execute only a part of this workflow, you can either modify the `fullUpdate` script directly, or you can
make use of `rojo build` to build the packages, and `remodel run download.lua`, `remodel run update.lua` and `remodel run upload.lua`, which create, modify and read place files. See the respective scripts for usage details.

## Versioning

Package versions are assumed to be written to a `StringValue` called "version", which is parented to the top-level instance of the package. If no such `StringValue` is present, it will display as `package@unknown_version`

## Roblox Studio synchronisation

The "Version History" for a place is viewable at `https://www.roblox.com/places/<placeId>/update#`. This is a history of place-asset uploads, and whether or not they were published or just a "save". New place assets get uploaded here when they are delivered via `remodel.writeExistingAsset` (which also publishes them) or when they are saved or published from Roblox Studio.

Any published changes will not be visible in Roblox Studio if the place was already open when running the script.
Opening a place in Roblox studio amounts to grabbing the latest version from the version history (published or not), so if you save the old place in Roblox Studio after running the script, then that will be the version you get when you re-open the place Roblox Studio.

If you accidentally save over the changes you just published with this script, you can click "Revert To This Version" next to the version that was published by this script. This will make a clone that version as the latest saved version. The script also outputs a (UTC) timestamp that matches the datetime-format in the Version History, so you can use this to help identify the right version to revert to (it will probably be a few seconds later than the timestamp).

### Team Create

All of the above is true even when Team Create is on in the place, except "open in Roblox Studio" now means "open in any collaborator's Roblox Studio".
You should think of Team Create as being a server-side session of Roblox Studio that each collaborator can "remote-into". The place asset open in this session exists independently of any version saved to the Version History, so the saving/publishing relationship to the Version History is the same. However there are some important caveats.

**Important**: Team Create creates a save whenever the Team Create session closes - meaning when every collaborator has closed the place - and also auto-saves every 5 minutes. This means that if any collaborator has the place open in Roblox Studio when the script publishes a new version, it will be saved-over when 5 minutes pass or every collaborator closes the place. To see the new package updates you must do a version revert (or fresh publish) **while all collaborators have the place closed**. The new version will then be opened when any collaborator opens the place again.

With Team Create off, it is possible to just close and reopen Roblox Studio after you publish to see the new version, since it doesn't automatically create a save on close.

### Publishing workflow

If Team Create is off, there are less ways in which unintentional saves can happen, but it will still happen if someone clicks "Save to Roblox" on an old version they had open already. To make sure a package update never gets unintentionally saved-over, all collaborators should have the place closed in Roblox Studio **regardless of whether Team Create is on/off**. If Team Create is on, you can see who has it open in the Team Create window (View -> Team Create).

If it's just you in the session, you can simply close out of it, run the package updater, then rejoin and confirm you're seeing the latest version.

If there are other collaborators with the place open, you can then politely ask them to close, or you can force everyone to close by turning Team Create off, which shuts down the server-session. After running the package updating script you can then turn Team Create back on again.

Note: With or without team-create, there is always a possibility that someone opens the place in Roblox Studio just-before you run the package updating script, which means unless they can close without saving, they have the potential to create a save of the old-version over your changes. In such cases, you can make use of "Revert to this version" or just re-run the package update script as much as necessary, until you get a hold of your rogue collaborator.

### How do I know whether I'm seeing the latest changes?

You can check the `PackageUpdateChangeLog` script in `ServerStorage`, which includes the same (UTC) timestamp output from the script.
You can also put `print(game.PlaceVersion)` into the Command bar of Roblox Studio to see which "Version number" of the place you are currently seeing (compare to Version History).