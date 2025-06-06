FROM rocker/r-ver:4.2.2

#RUN sudo apt-get remove -y rstudio-server # only if tidyverse or verse base images used


# TeX layer
RUN apt-get update && apt-get install -y pandoc pandoc-citeproc texlive-science texlive-latex-extra texlive-lang-german

# System dependency layer
COPY etc/requirements-system.txt .
RUN apt-get update && apt-get -y install $(cat requirements-system.txt)

# Tesseract layer 
COPY etc/requirements-tesseract.sh .
RUN sh requirements-tesseract.sh

# R layer
COPY etc/requirements-R.R .
RUN Rscript requirements-R.R


# Config layers
WORKDIR /cd-icj
CMD "R"
