# Hello, World!

A program written in Go to only print `Hello World, from Zoi!` and handle errors.
This program is used as an example to packaging software.
In this guide we'll package this program to Zoi `hello.pkg.lua` format with three installation methods:

- Compressed Binary
- Binary
- Source

Also we'll guide you on how to build a `hello.pkg.tar.zst` package that contains everything to install the package offline locally for your system.

## Installation

You can install this program using Zoi by running one of these commands:

```sh
zoi install --repo Zillowe/Hello # this command just redirect to the bellow command
zoi install @zillowe/hello
```

## Setup

To follow this guide first you need to have [`zoi`](https://github.com/Zillowe/Zoi) installed, and `go` installed.

## Packaging

Now let's start packaging this program from this repo and its releases.

Now lets start by creating `hello.pkg.lua` and specify some metadata, Lua is the language Zoi uses for packaging software.

```lua
local repo_owner = "Zillowe"
local repo_name = "Hello"
local version = "2.0.0" -- latest version
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"
local release_base_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. "/releases/download/v" .. version

local platform_map = {
	macos = "darwin", -- this package uses 'darwin' instead of 'macos' and Zoi uses 'macos' by default, this and the other helper functions will help replacing 'macos' with 'darwin'
}

local function get_mapped_platform()
	local current_platform = SYSTEM.OS .. "-" .. SYSTEM.ARCH
	return platform_map[current_platform] or platform_map[SYSTEM.OS] or current_platform
end

-- Zoi provides SYSTEM.[OS, ARCH, DISTRO]

local function get_mapped_os()
	return get_mapped_platform():match("([^%-]+)")
end

package({
	name = "hello",
	repo = "zillowe",
	version = version,
	description = "Hello World",
	website = "https://github.com/Zillowe/Hello",
	git = git_url,
	man = "https://raw.githubusercontent.com/Zillowe/Hello/refs/heads/main/app/man.md", -- manual page, viewable with `zoi man` command
	maintainer = {
		name = "Your Name",
		email = "your@email.com",
	},
	author = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
		key = "https://zillowe.pages.dev/keys/zillowe-main.asc", -- for verifying signature
		key_name = "zillowe-main", -- specifying public key name so if its already in `zoi pgp` to use it instead of reimporting it
	},
	license = "Apache-2.0",
	bins = { "hello" }, -- binaries this package provides
	conflicts = { "hello" }, -- binaries this package conflicts with
})
```

Next lets define build dependencies:

```lua
dependencies({
	build = { -- build time dependencies, installed when building it from source
		required = { -- required build time dependencies, not optional
		  "native:go" -- this will install 'go' package from the native package manager, since go is pretty much widely available theres no need* to create a Zoi package for it
		  -- after the first 'sync' run 'zoi info' to see the list of available package managers and the native one for you
		},
	},
})
```

Now lets define the installation methods for this package inside a `install({})` block:

```lua
install({
	selectable = true, -- this means you can select which installation method you want by running the install command with '-i' flag
	{
		name = "Binary", -- name of the installation method
		type = "binary", -- type of the installation method
		url = (function() -- URL to the file
			return release_base_url .. "/hello-" .. get_mapped_os() .. "-" .. SYSTEM.ARCH
		end)(),
		platforms = { "linux", "macos", "windows" }, -- platforms this package support, [all, os-arch, os]
		checksums = (function() -- optional checksums verification
			return release_base_url .. "/checksums-512.txt"
		end)(),
		sigs = { -- optional signature verification against public key in maintainer or author fields
			{
				file = (function()
					return "hello-" .. get_mapped_os() .. "-" .. SYSTEM.ARCH
				end)(),
				sig = (function()
					return release_base_url .. "/hello-" .. get_mapped_os() .. "-" .. SYSTEM.ARCH .. ".sig"
				end)(),
			},
		},
	},
	{
		name = "Compressed Binary", -- same as above
		type = "com_binary",
		url = (function()
			local ext -- the extension type, Zoi supports [zip, tar.xz, tar.gz, tar.zst]
			if SYSTEM.OS == "windows" then
				ext = "zip"
			else
				ext = "tar.xz"
			end
			return release_base_url .. "/hello-" .. get_mapped_os() .. "-" .. SYSTEM.ARCH .. "." .. ext
		end)(),
		platforms = { "linux", "macos", "windows" },
		checksums = (function()
			return release_base_url .. "/checksums-512.txt"
		end)(),
		sigs = {
			{
				file = (function()
					local ext
					if SYSTEM.OS == "windows" then
						ext = "zip"
					else
						ext = "tar.xz"
					end
					return "hello-" .. get_mapped_os() .. "-" .. SYSTEM.ARCH .. "." .. ext
				end)(),
				sig = (function()
					local ext
					if SYSTEM.OS == "windows" then
						ext = "zip"
					else
						ext = "tar.xz"
					end
					return release_base_url
							.. "/hello-"
							.. get_mapped_os()
							.. "-"
							.. SYSTEM.ARCH
							.. "."
							.. ext
							.. ".sig"
				end)(),
			},
		},
	},
	{
		name = "Build from source",
		type = "source", -- building from source
		url = git_url, -- cloning the git repo, we can specify a branch or a tag
		platforms = { "linux", "macos", "windows" },
		build_commands = {
			'go build -o hello -ldflags="-s -w" src',
		},
		bin_path = (function() -- the final binary path
          local bin
					if SYSTEM.OS == "windows" then
						bin = "hello.exe"
					else
						bin = "hello"
					end
					return bin
				end)(),
	},
})
```

The official final `pkg.lua` is [this](./app/hello.pkg.lua).

## Building

Now you have a complete `hello.pkg.lua` package.

Now we need to run this command:

```sh
zoi package meta hello.pkg.lua # you can specify '--type' to use that installation methods instead, by default: 1. Compressed Binary, 2. Binary, 3. Source
```

This command will generate a `hello.meta.json` that contains all the metadata we need to build it.

Now run this command to build the package:

```sh
zoi package build hello.meta.json # you can specify '--platform', The platform to build for (e.g. 'linux-amd64', 'windows-arm64', 'all', 'current'). Can be specified multiple times [default: current]
```

This will build a package archive `hello-2.0.0-{os}-{arch}.pkg.tar.zst` and contains the binary and the manual if available, the build command will verify the checksums and the signatures.

To install the archive run this command:

```sh
zoi package install hello-2.0.0-{os}-{arch}.pkg.tar.zst # you can specify '--scope', The scope to install the package to (user or system-wide) [default: user]
```

This command will install the binary to its location and will install the manual if available.
