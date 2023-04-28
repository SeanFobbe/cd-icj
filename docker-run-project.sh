#!/bin/bash
set -e

time docker build -t cd-icj:4.2.2 .

time docker-compose run --rm cd-icj Rscript run_project.R
