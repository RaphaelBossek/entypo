Development docs
================

Set if scripts to easily build webfonts from SVG images

Installation on Ubuntu 12.04 (or newer)
---------------------------------------

**(!)** Use Ubuntu **12.04**. Or you will have to manually install fresh
freetype library, to build ttfautohint.

Reset the environment first

    make clean

Install the latest Node.js environment for your Ubuntu version from
https://launchpad.net/~chris-lea/+archive/node.js/ 

Install system dependencies (fontforge & python modules):

    sudo make dev-deps

Init font-builder and build additional software (ttf2eot, ttfautohint)
including the font himself:

    make


If you are working on multiple font you would like to have only one instance of
heavy dependencies like _ttfautohint_ installed. Run this:

    sudo make -C support/font-builder support-install


Note that you don't need to install system dependencies more than once.


Making font
-----------

### Steps

1. Place images into `/src/svg` folder.
2. Add image info to `config.yml` (see comments in it)
3. Edit css/html templates, if needed.
4. Run `make`

Generated data will be placed in `./font`

You can rebuild css/html only with `make html`

### SVG image requirements

Any image will be proportionnaly scaled, to fit height in ascent-descent
It's convenient to make height = 1000px. Default font baseline will be 20% from
the bottom.

In most cases it's ok to visually allign icons to middle line, not to baseline.
If you are not shure, how to start - make image with 10% top/bottom padding.
Then generate demo page and tune scale/offset.
