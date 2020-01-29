.PHONY: serve build


serve:
	JEKYLL_ENV=development jekyll serve --incremental

build:
	JEKYLL_ENV=development jekyll build
