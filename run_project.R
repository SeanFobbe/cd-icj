#'# Load Package
library(rmarkdown)


#'# Datestamp
datestamp <- Sys.Date()



#+
#'# Data Set
#' To compile the full data set and generate a PDF report, copy all files provided in the Source ZIP Archive into an empty (!) folder and use the command below from within an R session:

rmarkdown::render(input = "CD-ICJ_Source_CorpusCreation.R",
                  output_file = paste0("CD-ICJ_",
                                       datestamp,
                                       "_CompilationReport.pdf"),
                  envir = new.env())


#+
#'# Codebook
#' To compile the Codebook, after you have run the Corpus Creation script, use the command below from within an R session:

rmarkdown::render(input = "CD-ICJ_Source_CodebookCreation.R",
                  output_file = paste0("CD-ICJ_",
                                       datestamp,
                                       "_Codebook.pdf"),
                  envir = new.env())
