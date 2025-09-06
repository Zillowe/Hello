# Hello, World!

A program written in C to only print `Hello, World!` and handle errors.
This program is used as an example to packaging software.
In this guide we'll package this program to Zoi `hello.pkg.lua` format with three installation methods:

- Compressed Binary
- Binary
- Source

Also we'll guide you on how to build a `hello.pkg.tar.zst` package that contains everything to install the package offline locally for your system.

## Setup

To follow this guide first you need to have [`zoi`](https://github.com/Zillowe/Zoi) installed, and we'll use `gcc`, `meson` and `ninja` for compiling and building this program, you can use whatever you like.

Now let's test the program:

```sh
meson setup builddir
meson compile -C builddir # you can cd into builddir and run `ninja` instead
./builddir/hello # .exe if you're on windows
$ Hello, World! # it works!
```

## Packaging

Now let's start packaging this program from this repo and its releases.
