.PHONY: serve build


serve:
	JEKYLL_ENV=production jekyll serve

build:
	jekyll build
