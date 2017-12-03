.PHONY: serve build


serve:
	JEKYLL_ENV=development jekyll serve

build:
	JEKYLL_ENV=development jekyll build
