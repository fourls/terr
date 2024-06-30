# `terr`

`terr` is a command line tool to assist with installing and maintaining a dedicated server for
[Terraria](https://terraria.org/).

Both MacOS and Linux devices are supported.

## Getting started

Copy `terr` into a directory of your choice - it is recommended to put it on PATH
so it can be accessed from anywhere.

```sh
# Create a new folder to put your Terraria data in
mkdir terr_data
cd terr_data

# Install the Terraria dedicated server and configure default settings
terr install

# Start the Terraria server without booting into a specific world
terr choose

# Start the Terraria server in the background with the given world
terr start <your world>
```

## Features

### Easy install

It can be a little tricky to determine exactly how to download and run the dedicated server - so `terr` takes
the guesswork away.

* `terr install` automatically downloads the official dedicated server from [terraria.org](https://terraria.org/)
  and sets up a default config file
* `terr config` allows you to update config values easily

### Running in the background

The dedicated server does not deal well with being backgrounded, so using the terminal for anything else - or
keeping the server running after closing the terminal - requires extra tooling. `terr` abstracts this away.

* `terr start <world>` - Run the server as a background process
* `terr join` - Attach to the server process (you can then detach with `ctrl+B d`)

This feature uses [tmux](https://github.com/tmux/tmux/wiki). If you would rather run the server without `tmux`,
`terr run <world>` and `terr choose` run the server directly.

### Handling worlds

The server makes it tricky to auto-boot into worlds, since you have to specify the full path to the world file
in order to do so. `terr` makes this easier by managing the world path for you:

* `terr worlds` lists all saved worlds
* `terr run` and `terr start` require you to specify a world, which is the name of the world file without `.wld`
* `terr choose` saves worlds to the correct location
* `terr backup` provides an easy way to copy world files

### File logging

The dedicated server has no inbuilt support for logging to a file, making it difficult to monitor the server without
actively watching its output. `terr` automatically logs all input and output to a timestamped file in your Terraria
setup's `logs` subdirectory.

### Setting the `terr` home directory

`terr` assumes your Terraria setup is in the current working directory by default, but this can be overridden
by setting the `TERR_HOME` environment variable. This means that you can manage your server from anywhere
on the filesystem, without having to awkwardly `cd` to the right place each time.