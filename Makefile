PROJECT     := $(notdir ${PWD})
FONT_NAME   := entypo


################################################################################
## ! DO NOT EDIT BELOW THIS LINE, UNLESS YOU REALLY KNOW WHAT ARE YOU DOING ! ##
################################################################################


TMP_PATH    := /tmp/${PROJECT}-$(shell date +%s)
REMOTE_NAME ?= origin
REMOTE_REPO ?= $(shell git config --get remote.${REMOTE_NAME}.url)


# Add local versions of ttf2eot nd ttfautohint to the PATH
PATH := $(PATH):./support/font-builder/support/ttf2eot
PATH := $(PATH):./support/font-builder/support/ttfautohint/frontend
PATH := $(PATH):./support/font-builder/bin
PATH := $(PATH):./bin
FONTFORGE ?= $(shell which fontforge)
RM_F ?= rm -f

all:	dist
dist: font html

dump:	src/svg/note.svg
src/svg/note.svg:	src/original/entypo.svg src/original/entypo-social.svg config.yml
	rm -rf src/svg
	mkdir src/svg
	font-dump.js --hcrop -c config.yml -f -i src/original/entypo.svg -o ./src/svg/ -d diff.yml
	font-dump.js --hcrop -c config.yml -f -i src/original/entypo-social.svg -o ./src/svg/ -d diff.yml

%.svg:	%.ttf
	: # FIXME How to autofix missed points in FontForge?
	$(FONTFORGE) -script ./bin/ffttf2svg.pe "$<" "$@.svg"
	: # Changed descent to 0, accent to 500, to fix scale
	sed -e 's,units-per-em="1000",units-per-em="500",g;s,ascent="750",ascent="500",g;s,descent="-250",descent="0",g' "$@.svg" >"$@"
	rm "$@.svg"

%.ttf:
	update-entypo.sh src/original
	$(RM_F) src/original/*.svg

src/original/entypo.svg:	src/original/entypo.ttf
src/original/entypo-social.svg:	src/original/entypo-social.ttf

font:	font/$(FONT_NAME).ttf font/$(FONT_NAME).eot
font/$(FONT_NAME).ttf font/$(FONT_NAME).eot:	support dump
	rm -rf font
	mkdir -p font
	fontbuild.py -c ./config.yml -t ./src/font_template.sfd -i ./src/svg -o ./font/$(FONT_NAME).ttf
	ttfautohint --latin-fallback --hinting-limit=200 --hinting-range-max=50 --symbol ./font/$(FONT_NAME).ttf ./font/$(FONT_NAME)-hinted.ttf
	mv ./font/$(FONT_NAME)-hinted.ttf ./font/$(FONT_NAME).ttf
	fontconvert.py -i ./font/$(FONT_NAME).ttf -o ./font
	ttf2eot < ./font/$(FONT_NAME).ttf >./font/$(FONT_NAME).eot


package.json:	support/font-builder/package.json
	ln -s $<

npm-deps:	node_modules/underscore
node_modules/underscore:	package.json
	@if test ! `which npm` ; then \
		echo "Node.JS and NPM are required for html demo generation." >&2 ; \
		echo "This is non-fatal error and you'll still be able to build font," >&2 ; \
		echo "however, to build demo with >> make html << you need:" >&2 ; \
		echo "  - Install Node.JS and NPM" >&2 ; \
		echo "  - Run this task once again" >&2 ; \
		exti 127; \
		fi
	: npm install jade js-yaml.bin
	npm install

support:	support/font-builder/support/ttf2eot/ttf2eot support/font-builder/support/ttfautohint/frontend/ttfautohint npm-deps

support/font-builder/Makefile support/font-builder/package.json:
	git submodule init support/font-builder
	git submodule update support/font-builder

support/font-builder/support/ttf2eot/ttf2eot support/font-builder/support/ttfautohint/frontend/ttfautohint:	support/font-builder/Makefile
	$(MAKE) -C support/font-builder

html:	font/demo.html
font/demo.html:	support src/demo/demo.jade
	tpl-render.js --locals config.yml --input ./src/demo/demo.jade --output ./font/demo.html


gh-pages:
	@if test -z ${REMOTE_REPO} ; then \
		echo 'Remote repo URL not found' >&2 ; \
		exit 128 ; \
		fi
	cp -r ./font ${TMP_PATH} && \
		touch ${TMP_PATH}/.nojekyll
	cd ${TMP_PATH} && \
		git init && \
		git add . && \
		git commit -q -m 'refreshed gh-pages'
	cd ${TMP_PATH} && \
		git remote add remote ${REMOTE_REPO} && \
		git push --force remote +master:gh-pages 
	rm -rf ${TMP_PATH}

dev-deps:	support/font-builder/Makefile
	$(MAKE) -C support/font-builder $@
	apt-get install -f fontforge nodejs

clean:
	rm -rf font src/svg src/original support/font-builder node_modules
	-test -L package.json && rm package.json
	$(MAKE) support/font-builder/Makefile

.PHONY: dist dump font npm-deps support html clean dev-deps
