.PHONY: serve build


serve:
	JEKYLL_ENV=development jekyll serve

build:
	jekyll build
