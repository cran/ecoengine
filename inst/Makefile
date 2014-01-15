all : pdf

pdf : $(patsubst %.Rmd, %.pdf, $(wildcard *.Rmd))	

%.md : %.Rmd
	Rscript -e "library(knitr); knit('$<')" 

%.pdf : %.md 
	pandoc $< -o $@ -H ~/margins
	open *.pdf