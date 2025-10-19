# Hello, World!

A program written in Zig to only print `Hello, World!` and handle errors. This program is used as an example to demonstrate how to package software for Zoi.

In this guide, we'll walk through the provided `app/hello.pkg.lua` file to understand how it's packaged for Zoi, supporting both pre-compiled and from-source installation methods.

## Installation

You can install this program using Zoi by running one of these commands:

```sh
zoi install --repo Zillowe/Hello # This command redirects to the one below
zoi install @zillowe/hello
```

## Setup

To follow this guide and build the package yourself, you need to have [`zoi`](https://github.com/Zillowe/Zoi) and `zig` installed.

## Packaging `hello.pkg.lua` Explained

Zoi uses Lua scripts (`.pkg.lua` files) to define packages. Let's break down the official `hello.pkg.lua` file.

### 1. Helper Variables and Functions

The script starts by defining some local variables and helper functions to keep the code clean. This is standard Lua practice.

```lua
local repo_owner = "Zillowe"
local repo_name = "Hello"
local version = ZOI.VERSION or "3.0.0" -- Use version from Zoi runtime or default
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"
local release_base_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. "/releases/download/v" .. version

-- Helper to map Zoi's OS name to the one used in the release assets
local platform_map = {
	macos = "darwin",
}
-- ... more helper functions
```

### 2. The `metadata` Function

This is the heart of the package, defining all its core properties.

```lua
metadata({
	name = "hello",
	repo = "zillowe",
	version = version,
	description = "Hello World",
	website = "https://github.com/Zillowe/Hello",
	git = git_url,
	man = "https://raw.githubusercontent.com/Zillowe/Hello/refs/heads/main/app/man.md",
	maintainer = { ... },
	author = { ... },
	license = "Apache-2.0",
	bins = { "hello" }, -- The executable(s) this package provides
	conflicts = { "hello" }, -- Other commands this package might conflict with
	types = { "source", "pre-compiled" }, -- The build methods this package supports
})
```

### 3. The `dependencies` Function

Here, we define any build-time or runtime dependencies. This package needs `zig` to build from source.

```lua
dependencies({
	build = { -- build-time dependencies
		required = {
		  "native:zig" -- Install 'zig' from the native system package manager
		},
	},
})
```

### 4. The `prepare` Function

This function prepares the source code for building. It's called first in the build process. The logic is branched based on the `BUILD_TYPE` global variable, which is set by the `--type` flag of the `zoi package build` command.

```lua
function prepare()
	-- For pre-compiled builds, download and extract the release archive
	if BUILD_TYPE == "pre-compiled" then
		-- ... constructs URL for the release asset ...
		local url = release_base_url .. "/" .. file_name
		UTILS.EXTRACT(url, "precompiled") -- Download and extract

	-- For source builds, clone the git repository
	elseif BUILD_TYPE == "source" then
		cmd("git clone " .. PKG.git .. " " .. BUILD_DIR .. "/source")
		cmd("cd " .. BUILD_DIR .. "/source && zig build-exe main.zig -O ReleaseSmall --name hello")
	end
end
```

### 5. The `package` Function

After `prepare`, the `package` function is called. Its job is to copy the final build artifacts into the staging area using the `zcp` command. The `${pkgstore}` variable points to the final installation directory.

```lua
function package()
	local bin_name = "hello"
	if SYSTEM.OS == "windows" then
		bin_name = "hello.exe"
	end

	if BUILD_TYPE == "pre-compiled" then
		-- Find the binary in the extracted directory
		local bin_path = UTILS.FIND.file("precompiled", bin_name)
		zcp(bin_path, "${pkgstore}/bin/" .. bin_name)
	elseif BUILD_TYPE == "source" then
		-- Copy the binary from the build directory
		zcp("source/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end
```

### 6. The `verify` Function

This optional step is crucial for security. It runs after `package` to verify the integrity of the downloaded files. If this function returns `false`, the build is aborted.

```lua
function verify()
	if BUILD_TYPE == "pre-compiled" then
		-- ... logic to get checksum and signature files ...

		-- Verify checksum
		if not verifyHash(file_path, "sha512-" .. expected_checksum) then
			return false
		end

		-- Verify PGP signature
		if not verifySignature(file_path, sig_path, "zillowe-main") then
			return false
		end

		return true
	end
	return true -- Always pass for source builds in this example
end
```

## Building the Package

Now that you have a complete `hello.pkg.lua` file, you can build it into a distributable package archive.

Run the `zoi package build` command, specifying a build type.

```sh
# Build the pre-compiled version
zoi package build ./app/hello.pkg.lua --type pre-compiled

# Or, build from source
zoi package build ./app/hello.pkg.lua --type source
```

This command will:

1.  Create a temporary build environment.
2.  Run the `prepare`, `package`, and `verify` functions from your script.
3.  Bundle the results into a `hello-3.0.0-{os}-{arch}.pkg.tar.zst` archive in the same directory.

## Installing the Local Archive

You can test your final package archive by installing it locally.

```sh
zoi package install ./hello-3.0.0-linux-amd64.pkg.tar.zst
```

This command unpacks the archive and installs the package just as if it were downloaded from a registry, allowing you to perform a final end-to-end test.
