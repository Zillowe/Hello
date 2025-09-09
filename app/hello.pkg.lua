local repo_owner = "Zillowe"
local repo_name = "Hello"
local version = "2.0.0"
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"
local release_base_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. "/releases/download/v" .. version

local platform_map = {
  macos = "darwin",
}

local function get_mapped_platform()
  local current_platform = SYSTEM.OS .. "-" .. SYSTEM.ARCH
  return platform_map[current_platform] or platform_map[SYSTEM.OS] or current_platform
end

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
  man = "https://raw.githubusercontent.com/Zillowe/Hello/refs/heads/main/app/man.md",
  maintainer = {
    name = "Zillowe Foundation",
    website = "https://zillowe.qzz.io",
    email = "contact@zillowe.qzz.io",
  },
  author = {
    name = "Zillowe Foundation",
    website = "https://zillowe.qzz.io",
    email = "contact@zillowe.qzz.io",
    key = "https://zillowe.pages.dev/keys/zillowe-main.asc",
    key_name = "zillowe-main",
  },
  license = "Apache-2.0",
  bins = { "hello" },
  conflicts = { "hello" },
})

install({
  selectable = true,
  {
    name = "Binary",
    type = "binary",
    url = (function()
      return release_base_url .. "/hello-" .. get_mapped_os() .. "-" .. SYSTEM.ARCH
    end)(),
    platforms = { "linux", "macos", "windows" },
    checksums = (function()
      return release_base_url .. "/checksums-512.txt"
    end)(),
    sigs = {
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
    name = "Compressed Binary",
    type = "com_binary",
    url = (function()
      local ext
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
    type = "source",
    url = git_url,
    platforms = { "linux", "macos", "windows" },
    build_commands = {
      'go build -o hello -ldflags="-s -w" ./src',
    },
    bin_path = (function()
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

dependencies({
  build = {
    required = { "native:go" },
  },
})
