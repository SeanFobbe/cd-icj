#'---
#'title: "Compilation Report | Corpus of Decisions: International Court of Justice (CD-ICJ)"
#'author: Seán Fobbe
#'geometry: margin=3cm
#'papersize: a4
#'fontsize: 11pt
#'output:
#'  pdf_document:
#'    keep_tex: true
#'    toc: true
#'    toc_depth: 3
#'    number_sections: true
#'    pandoc_args: --listings
#'    includes:
#'      in_header: tex/CD-ICJ_Source_TEX_Preamble_EN.tex
#'      before_body: [tex/CD-ICJ_Source_TEX_Author.tex,temp/CD-ICJ_Source_TEX_Definitions.tex,tex/CD-ICJ_Source_TEX_CompilationTitle.tex]
#'bibliography: temp/packages.bib
#'nocite: '@*'
#'---



#'\newpage

#+ results = "asis"
cat(readLines("README.md"),
    sep = "\n")



#'\newpage
#'# Preamble

#+
#'## Datestamp
#' This datestamp will be applied to all output files. It is set at the beginning of the script so it will be held constant for all output even if long runtime breaks the date barrier.

datestamp <- Sys.Date()
print(datestamp)


#'## Date and Time (Begin)
begin.script <- Sys.time()
print(begin.script)


#+
#'## Load Packages

library(RcppTOML)      # Read and write TOML files
library(httr)          # HTTP Tools
library(rvest)         # Web Scraping
library(mgsub)         # Vectorized Gsub
library(stringr)       # String Manipulation
library(pdftools)      # PDF utilities
library(fs)            # File Operations
library(knitr)         # Scientific Reporting
library(kableExtra)    # Enhanced Knitr Tables
library(magick)        # Required for cropping when compiling PDF
library(DiagrammeR)    # Graph/Network Visualization 
library(DiagrammeRsvg) # Export DiagrammeR Graphs as SVG
library(rsvg)          # Render SVG to PDF
library(ggplot2)       # Advanced Plotting
library(scales)        # Rescaling of Plots
library(viridis)       # Viridis Color Palette
library(RColorBrewer)  # ColorBrewer Palette
library(readtext)      # Read TXT Files
library(quanteda)      # Advanced Text Analytics
library(quanteda.textstats)  # Text Statistics Tools
library(quanteda.textplots)  # Specialized Plots for Text Statistics
library(textcat)       # Classify Text Language
library(data.table)    # Advanced Data Handling
library(doParallel)    # Parallelization




#'## Load Additional Functions
#' **Note:** Each custom function will be printed in full prior to its first use in order to enhance readability. All custom functions are prefixed with \enquote{f.} for clarity.

lapply(list.files("functions", pattern = "\\.R$", full.names = TRUE), source)






#'# Parameters




#+
#'## Output Directory
#' The directory name must include a terminating slash!
outputdir <- paste0(getwd(),
                    "/ANALYSIS/")



#+
#'## Read Configuration File
#' All configuration options are set in a separate configuration file that is read here. They should only be changed in that file!


config <- RcppTOML::parseTOML("config.toml")
print(config)



#+
#'## Name of Data Set

datashort <- config$project$shortname
print(datashort)


#'## DOI of Data Set Concept

doi.concept <- config$doi$data$concept
print(doi.concept)


#'## DOI of Specific Version

doi.version <- config$doi$data$version
print(doi.version)


#'## License
license <- config$license$data
print(license)




#'## Scope: Case Numbers
#' These variables define the scope of cases (by ordinal number) to be compiled into the data set. 
#'
#' Case number 2 appears to be unassigned. There is no information available on the ICJ website. It is therefore always excluded.
#'
#' The variable for the final case number --- caseno.end --- must be set manually.

caseno.begin  <- config$caseno$begin
caseno.end <- config$caseno$end
caseno.exclude <- config$caseno$exclude

print(caseno.begin)
print(caseno.end)
print(caseno.exclude)


#'## Debugging Mode
#' The debugging mode will reduce the number of documents compiled significantly. The full complement of cases takes approximately 11 hours to process with 16 threads on a Ryzen 3700X. The reduced complement captures a variety of cases with key characteristics that are useful in testing all features. Testing should always include cases 116 and 146 or an error will occur.
#'
#' In addition to the mandatory test cases debugging mode will draw two random samples of size *debug.sample*, one from older and one from more recent cases of the ICJ.


mode.debug.toggle <- config$debug$toggle
mode.debug.sample <- config$debug$sample

print(mode.debug.toggle)
print(mode.debug.sample)



#'## DPI for OCR
#' This is the resolution at which PDF files will be converted to TIFF during the OCR step. DPI values will significantly affect the quality of text ouput and file size. Higher DPI requires more RAM, means higher quality text and greater PDF file size. A value of 300 is recommended.

ocr.dpi <- config$ocr$dpi
print(ocr.dpi)




#'## Frequency Tables: Ignored Variables

#' This is a character vector of variable names that will be ignored in the construction of frequency tables.
#'
#' It is a good idea to add variables to this list that are unlikely to produce useful frequency tables. This is often the case for variables with a very large proportion of unique values. Use this option judiciously, as frequency tables are useful for detecting anomalies in the metadata.


freq.var.ignore <- config$freqvar$ignore
print(freq.var.ignore)


#'## Set Download Timeout
options(timeout = config$download$timeout)



#'## Knitr Options

#+
#'### Image Output File Formats

fig.format <- config$fig$format
print(fig.format)


#'### DPI for Raster Graphics

fig.dpi <- config$fig$dpi
print(fig.dpi)



#'### Alignment of Diagrams in Report

fig.align <- config$fig$align
print(fig.align)



#'### Set Knitr Options
knitr::opts_chunk$set(fig.path = outputdir,
                      dev = fig.format,
                      dpi = fig.dpi,
                      fig.align = fig.align)









#'# Manage Directories

#+
#'## Define Set of Data Directories

dirset <- c("EN_PDF_ORIGINAL_FULL",
             "FR_PDF_ORIGINAL_FULL",
             "EN_PDF_ENHANCED_max2004",
             "FR_PDF_ENHANCED_max2004",
             "EN_PDF_BEST_FULL",
             "FR_PDF_BEST_FULL",
             "EN_PDF_BEST_MajorityOpinions",
             "FR_PDF_BEST_MajorityOpinions",
             "EN_TXT_BEST_FULL",
             "FR_TXT_BEST_FULL",
             "EN_TXT_TESSERACT_max2004",
             "FR_TXT_TESSERACT_max2004",
             "EN_TXT_EXTRACTED_FULL",
             "FR_TXT_EXTRACTED_FULL")





#'## Directory for Unlabelled Files

dir.unlabelled <- paste(datashort,
                        datestamp,
                        "UnlabelledFiles",
                        sep = "_")



#'## Clean up files from previous runs


delete <- list.files(pattern = "\\.pdf|\\.zip|\\.pdf|\\.csv|\\.tex")
unlink(delete)



for (dir in dirset){
    unlink(dir, recursive = TRUE)
}

unlink(outputdir, recursive = TRUE)
unlink(dir.unlabelled, recursive = TRUE)
unlink("temp", recursive = TRUE)


#'## Create directories

for (dir in dirset){
    dir.create(dir)
}


dir.create("temp")
dir.create(dir.unlabelled)
dir.create(outputdir)













#'# LaTeX Configuration

#+
#'### Construct LaTeX Definitions

latexdefs <- c("%===========================\n% Definitions\n%===========================",
               "\n% NOTE: This file was created automatically during the compilation process.\n",
               "\n%-----Version-----",
               paste0("\\newcommand{\\version}{",
                      datestamp,
                      "}"),
               "\n%-----Titles-----",
               paste0("\\newcommand{\\datatitle}{",
                      config$project$fullname,
                      "}"),
               paste0("\\newcommand{\\datashort}{",
                      config$project$shortname,
                      "}"),
               paste0("\\newcommand{\\softwaretitle}{Source Code for the \\enquote{",
                      config$project$fullname,
                      "}}"),
               paste0("\\newcommand{\\softwareshort}{",
                      config$project$shortname,
                      "-Source}"),
               "\n%-----Data DOIs-----",
               paste0("\\newcommand{\\dataconceptdoi}{",
                      config$doi$data$concept,
                      "}"),
               paste0("\\newcommand{\\dataversiondoi}{",
                      config$doi$data$version,
                      "}"),
               paste0("\\newcommand{\\dataconcepturldoi}{https://doi.org/",
                      config$doi$data$concept,
                      "}"),
               paste0("\\newcommand{\\dataversionurldoi}{https://doi.org/",
                      config$doi$data$version,
                      "}"),
               "\n%-----Software DOIs-----",
               paste0("\\newcommand{\\softwareconceptdoi}{",
                      config$doi$software$concept,
                      "}"),
               paste0("\\newcommand{\\softwareversiondoi}{",
                      config$doi$software$version,
                      "}"),

               paste0("\\newcommand{\\softwareconcepturldoi}{https://doi.org/",
                      config$doi$software$concept,
                      "}"),
               paste0("\\newcommand{\\softwareversionurldoi}{https://doi.org/",
                      config$doi$software$version,
                      "}"))



#'\newpage
#'### Write LaTeX Definitions

writeLines(latexdefs,
           "temp/CD-ICJ_Source_TEX_Definitions.tex")




#'## Write Package Citations
write_bib(c(.packages()),
          "temp/packages.bib")





#'# Parallelization
#' Parallelization is used for many tasks in this script, e.g. for accelerating the conversion from PDF to TXT, OCR, analysis with **quanteda** and with **data.table**. The maximum number of cores will automatically be detected and used.
#'
#' The download of decisions from the ICJ website is not parallelized to ensure respectful use of the Court's bandwidth.
#'
#' The use of **fork clusters** is significantly more efficient than PSOCK clusters, although it restricts use of this script to Linux systems.

#+
#'## Detect Number of Logical Cores
#' This will detect the maximum number of threads (= logical cores) available on the system or set them according to the config file.

if(config$cores$max == TRUE){

    fullCores <- detectCores()

}else{

    fullCores <- config$cores$number
    
}

print(fullCores)



#'## Set Number of OCR Control Cores
#' **Note:** Reduced number of control cores for OCR, as Tesseract calls up to four threads by itself.
ocrCores <- round((fullCores / 4)) + 1  
print(ocrCores)

#'## Data.table
setDTthreads(threads = fullCores)

#'## Quanteda
quanteda_options(threads = fullCores)    










#'# Visualize Corpus Creation Process

#+
#'## Workflow Part 1


workflow1 <- "
digraph workflow {

  # a 'graph' statement
  graph [layout = dot, overlap = false]

  # Legend

  subgraph cluster1{
      peripheries=1
  9991 [label = 'Data Nodes', shape = 'ellipse', fontsize = 22]
  9992 [label = 'Action Nodes', shape = 'box', fontsize = 22]
}


  # Data Nodes

  node[shape = 'ellipse', fontsize = 22]

  100 [label = 'www.icj-cij.org']
  101 [label = 'Links to Raw PDF Files']
  102 [label = 'Unlabelled Files']
  103 [label = 'Labelling Information']
  104 [label = 'Labelled PDF Files']
  105 [label = 'Handcoded Case Names']

  106 [label = 'EN_PDF_ORIGINAL_FULL']
  107 [label = 'EN_TXT_EXTRACTED']
  108 [label = 'EN_TXT_TESSERACT_max2004']
  109 [label = 'EN_PDF_ENHANCED_Max2004']
  110 [label = 'EN_TXT_BEST']
  111 [label = 'EN_PDF_BEST_FULL']
  112 [label = 'EN_PDF_BEST_MajorityOpinions']

  113 [label = 'FR_PDF_ORIGINAL_FULL']
  114 [label = 'FR_TXT_EXTRACTED']
  115 [label = 'FR_TXT_TESSERACT_max2004']
  116 [label = 'FR_PDF_ENHANCED_Max2004']
  117 [label = 'FR_TXT_BEST']
  118 [label = 'FR_PDF_BEST_FULL']
  119 [label = 'FR_PDF_BEST_MajorityOpinions']


  # Action Nodes

  node[shape = 'box', fontsize = 22]

  200 [label = 'Extract Links from HTML']
  201 [label = 'Detect Unlabelled Files']
  202 [label = 'Download Unlabelled Files']
  203 [label = 'Handcoding of Labels'] 
  204 [label = 'Apply Labelling']
  205 [label = 'Strict REGEX Validation: ICJ File Name Schema']
  206 [label = 'Download Module']
  207 [label = 'File Split Module']
  208 [label = 'Filename Enhancement Module']
  209 [label = 'Strict REGEX Validation: Codebook File Name Schema']
  210 [label = 'Detect Missing Language Counterparts']
  211 [label = 'Text Extraction Module']
  212 [label = 'Tesseract OCR Module']
  213 [label = 'Create Majority Variant']


  # Edge Statements
  100 -> 200 -> 101 -> 201 -> 202 -> 102
  102 -> 203 -> 103
  {101, 103} -> 204 -> 205 -> 206 -> 104  -> 207 -> 208 -> 209 -> {106,113} -> 210 -> {211, 212}
  105 -> 208
  211 -> {107, 114}
  212 -> {108, 109, 115, 116}
  {107, 108} -> 110
  {106, 109} -> 111
  {114, 115} -> 117
  {113, 115} -> 118 
  111 -> 213 -> 112
  118 -> 213 -> 119
  
}
"



grViz(workflow1) %>% export_svg %>% charToRaw %>% rsvg_pdf("ANALYSIS/CD-ICJ_Workflow_1.pdf")
grViz(workflow1) %>% export_svg %>% charToRaw %>% rsvg_png("ANALYSIS/CD-ICJ_Workflow_1.png")



#' \begin{sidewaysfigure}
#'\includegraphics{ANALYSIS/CD-ICJ_Workflow_1.pdf}
#' \caption{Workflow Part 1: Download, Labelling, Conversion and Sorting of Documents}
#' \end{sidewaysfigure}















#+
#'## Workflow Part 2


workflow2 <- "
digraph workflow {

  # Graph statement
  graph [layout = dot, overlap = false]

  # Data Nodes

  node[shape = 'ellipse', fontsize = 22]

  100 [label = 'EN_TXT_BEST']
  101 [label = 'FR_TXT_BEST']
  102 [label = 'EN_TXT_EXTRACTED']
  103 [label = 'FR_TXT_EXTRACTED']

  104 [label = 'EN_CSV_BEST_FULL']
  105 [label = 'FR_CSV_BEST_FULL']
  106 [label = 'EN_CSV_BEST_META']
  107 [label = 'FR_CSV_BEST_META']

  108 [label = 'ANALYSIS']
  109 [label = 'Frequency Tables']


  # Action Nodes

  node[shape = 'box', fontsize = 22]

  200 [label = 'OCR Quality Control Module']
  201 [label = 'Clean Texts']
  202 [label = 'Language Purity Module']
  203 [label = 'Add Metadata']
  204 [label = 'Calculate Frequency Tables']
  205 [label = 'Visualize Frequency Tables']
  206 [label = 'Calculate and Add Summary Statistics']
  207 [label = 'Calculate Token Frequencies']
  208 [label = 'Calculate Document Similarity']
  209 [label = 'Write CSV Files']


  # Edge Statements

  {100, 101, 102, 103} -> 200
  {100, 101} -> 201 -> 202 -> 203
  203 -> 204 -> 109 -> 205
  203 -> 206 -> 209
  203 -> {207, 208}
  {109, 204, 205, 206, 207, 208} -> 108
  209 -> {104, 105, 106, 107}

  
}
"

grViz(workflow2) %>% export_svg %>% charToRaw %>% rsvg_pdf("ANALYSIS/CD-ICJ_Workflow_2.pdf")
grViz(workflow2) %>% export_svg %>% charToRaw %>% rsvg_png("ANALYSIS/CD-ICJ_Workflow_2.png")


#' \begin{sidewaysfigure}
#'\includegraphics{ANALYSIS/CD-ICJ_Workflow_2.pdf}
#'  \caption{Workflow Part 2: Ingestion, Pre-Processing, Analysis and Creation of CSV Files}
#' \end{sidewaysfigure}





#+
#'# Prepare Download

#+
#'## Define Download Scope

caseno.full <- setdiff(caseno.begin:caseno.end,
                       caseno.exclude)


#'## Debugging Mode --- Reduced Scope

if(mode.debug.toggle == TRUE){
    caseno.full <- c(sample(3:41,
                            mode.debug.sample),
                     116,
                     146,
                     152,
                     153,
                     sample(154:caseno.end,
                            mode.debug.sample),
                     175)
    caseno.full <- sort(unique(caseno.full))
    }



#'## Show Function: f.linkextract
print(f.linkextract)

#'## Show Function: f.selectpdflinks
print(f.selectpdflinks)


#'## Prepare Empty Link List
links.list <- vector("list",
                     caseno.end)


#'## Acquire Download Links

for (caseno in caseno.full) {

    URL.JUD <- sprintf("https://www.icj-cij.org/en/case/%d/judgments",
                    caseno)
    
    volatile <- f.linkextract(URL.JUD)
    links.jud <- f.selectpdflinks(volatile)

    
    URL.ORD <- sprintf("https://www.icj-cij.org/en/case/%d/orders",
                    caseno)
    
    volatile <- f.linkextract(URL.ORD)
    links.ord <- f.selectpdflinks(volatile)

    
    URL.ADV <- sprintf("https://www.icj-cij.org/en/case/%d/advisory-opinions",
                    caseno)
    
    volatile <- f.linkextract(URL.ADV)
    links.adv <- f.selectpdflinks(volatile)

    
    links.list[[caseno]] <- c(links.jud,
                              links.ord,
                              links.adv)
    print(caseno)
    
    Sys.sleep(runif(1, 0.5, 1.5))
    
}


#'## Clean Links

links <- unlist(links.list)

links.download <- unique(links)



#'## Remove Specific Links
#' **Note 1:** All files related to the advisory opinion in Case 146 are bilingual, even the supposedly monolingual variants. This removes the monolingual variants without replacement. True monolingual variants will be generated via splitting the bilingual variants at a later stage.
#' 
#' **Note 2:** The French files for cases 89, 125 and 156 are in fact mislabelled English variants. No French variants of the document are available on the website and even the bilingual variants are in fact entirely in English.

f1 <- "(089-19990629-ORD-01-00-FR)"
f2 <- "(125-20040709-ORD-01-00-FR)"
f3 <- "(146-20120201-ADV-01-00)"
f4 <- "(156-20150422-ORD-01-01-FR)"

links.download <- grep(paste(f1, f2, f3, f4, sep = "|"),
                       links.download,
                       invert = TRUE,
                       value = TRUE)



#'## Add Specific Links
#' All files related to the advisory opinion in Case 146 are bilingual, even the supposedly monolingual variants. This adds the official bilingual advisory opinion and adds the bilingual appended opinions which were not included in the original link list. These files will be split into monolingual variants at a later stage of the script.


links.download <- c(links.download,
                    "https://www.icj-cij.org/public/files/case-related/146/146-20120201-ADV-01-00-BI.pdf",
                    "https://www.icj-cij.org/public/files/case-related/146/146-20120201-ADV-01-01-BI.pdf",
                    "https://www.icj-cij.org/public/files/case-related/146/146-20120201-ADV-01-02-BI.pdf")






#'# Labelling Module
#' Almost two dozen ICJ documents are unlabelled, i.e. they are provided with a computer-generated number only. Their filenames encode no semantic information. This module corrects the filenames and applies the standard naming scheme employed by the ICJ.

#+
#'## List Unlabelled Files

unlabelled.temp <- grep("EN|FR|BI",
                        links.download,
                        invert = TRUE,
                        value = TRUE)

unlabelled.out <- data.table(sort(unlabelled.temp),
                             sort(unlabelled.temp))

print(unlabelled.temp)


#'## Write to Disk

fwrite(unlabelled.out,
       paste0(dir.unlabelled,
              "/",
              datashort,
              "_",
              datestamp,
              "_",
              "UnlabelledFiles.csv"))



#'## Download Unlabelled Files
#' This is to prepare manual inspection and coding of unlabelled files.

#+
#'### Prepare

unlabelled.download.url <- paste0("https://www.icj-cij.org",
                                  unlabelled.temp)

unlabelled.download.name <- gsub("\\/", "\\_",
                                 unlabelled.temp)

unlabelled.download.name <- sub("\\_", "",
                                unlabelled.download.name)

dt <- data.table(unlabelled.download.url,
                 unlabelled.download.name)


#'### Number of Unlabelled Files to Download
dt[,.N]


#'### Timestamp (Unlabelled Download Begin)

begin.download <- Sys.time()
print(begin.download)


#'### Execute Download
#' **Note:** There is no download retry for this section, as these files are always inspected manually.

for (i in sample(dt[,.N])){
    download.file(dt$unlabelled.download.url[i],
                  dt$unlabelled.download.name[i])
    Sys.sleep(runif(1, 0.5, 1.5))
    }


#'### Timestamp (Unlabelled Download End)

end.download <- Sys.time()
print(end.download)

#'### Duration (Download)

end.download - begin.download





#'## Download Result

#+
#'### Number of Files to Download
download.expected.N <- dt[,.N]
print(download.expected.N)

#'### Number of Files Successfully Downloaded
files.pdf <- list.files(pattern = "\\.pdf",
                        ignore.case = TRUE)

download.success.N <- length(files.pdf)
print(download.success.N)

#'### Number of Missing Files
missing.N <- download.expected.N - download.success.N
print(missing.N)

#'### Names of Missing Files
missing.names <- setdiff(dt$unlabelled.download.name,
                         files.pdf)
print(missing.names)



#'## Store Unlabelled Files
file_move(files.pdf,
          dir.unlabelled)




#'## Manual Coding

#+
#########################################
###  HANDCODING OF UNLABELLED FILES
##########################################



#'## Read in Corrected Labels

unlabelled.in <- fread("data/CD-ICJ_Source_UnlabelledFilesHandcoded.csv",
                       header = TRUE)


#'## Apply Correct Labels to Link List

links.corrected <- mgsub(links.download,
                         unlabelled.in$old,
                         unlabelled.in$new)


#'## Correct Underscores

links.corrected <- gsub("_", "-", links.corrected)

#'## Correct Date Error

links.corrected <- gsub("202206613", "20220613", links.corrected)


#'## REGEX VALIDATION 1: Strictly Validate Links against ICJ Naming Scheme
#' Test strict compliance of proposed download names with naming scheme used by ICJ. The result of a successful test should be an empty character vector!

#+
#'### Execute Validation

regex.test1 <- grep(paste0("^[0-9]{3}", # var: caseno
                           "-",
                           "[0-9]{8}", # var: date
                           "-",
                           "(JUD|ADV|ORD)", # var: doctype
                           "-",
                           "[0-9]{2}", # var: collision
                           "-",
                           "[0-9]{2}", # var: opinion
                           "-",
                           "(EN|FR|BI)", # var: language
                           ".pdf$"), # file extension,
                    basename(links.corrected),
                    invert = TRUE,
                    value = TRUE)





#'### Results of Validation
print(regex.test1)

#'### Stop Script on Failure
if (length(regex.test1) != 0){
    stop("REGEX VALIDATION 1 FAILED: LINKS NOT IN COMPLIANCE WITH ICJ SCHEMA!")
    }



#'## Detect Duplicate Filenames
links.corrected[duplicated(links.corrected)]


#'## Detect Missing Counterparts for each Language Version

linknames.en <- grep("EN.pdf",
                     links.corrected,
                     value=TRUE)

linknames.fr <- grep("FR.pdf",
                     links.corrected,
                     value=TRUE)


#'## Difference in Number of Files
length(linknames.en) - length(linknames.fr)


#'## Show Missing French Documents
linknames.fr.temp <- gsub("FR",
                          "EN",
                          linknames.fr)

frenchmissing <- setdiff(linknames.en,
                         linknames.fr.temp)

frenchmissing <- gsub("EN",
                      "FR",
                      frenchmissing)

print(frenchmissing)


#'## Show Missing English Documents
linknames.en.temp <- gsub("EN",
                          "FR",
                          linknames.en)

englishmissing <- setdiff(linknames.fr,
                          linknames.en.temp)

englishmissing <- gsub("FR",
                       "EN",
                       englishmissing)

print(englishmissing)








#'# Download Module

#+
#'## Prepare Download Table

dt <- data.table(links.download,
                 basename(links.corrected))

setnames(dt,
         new = c("links.download",
                 "names.download"))


#'## Timestamp (Download Begin)
begin.download <- Sys.time()
print(begin.download)


#'## Execute Download (All Files)

for (i in sample(dt[,.N])){
    
    download.file(dt$links.download[i],
                  dt$names.download[i])
    
    Sys.sleep(runif(1, 0.5, 1.5))
    
}


#'## Timestamp (Download End)
end.download <- Sys.time()
print(end.download)


#'## Duration (Download)
end.download - begin.download




#'## Debugging Mode --- Delete Random Files
#' This section deletes random files to test the result calculations and retry mode.

if (mode.debug.toggle == TRUE){
    
    files.pdf <- list.files(pattern = "\\.pdf")
    
    unlink(sample(files.pdf, 5))
    
}






#'## Download Result

#+
#'### Number of Files to Download
download.expected.N <- dt[,.N]
print(download.expected.N)

#'### Number of Files Successfully Downloaded
files.pdf <- list.files(pattern = "\\.pdf",
                        ignore.case = TRUE)

download.success.N <- length(files.pdf)
print(download.success.N)

#'### Number of Missing Files
missing.N <- download.expected.N - download.success.N
print(missing.N)

#'### Names of Missing Files
missing.names <- setdiff(dt$names.download,
                         files.pdf)
print(missing.names)




#'## Timestamp (Retry Download Begin)
begin.download <- Sys.time()
print(begin.download)


#'## Retry Download

if(missing.N > 0){

    dt.retry <- dt[names.download %in% missing.names]
    
    for (i in 1:dt.retry[,.N]){
        
        response <- GET(dt.retry$links.download[i])
        
        Sys.sleep(runif(1, 0.25, 0.75))
        
        if (response$headers$"content-type" == "application/pdf" & response$status_code == 200){
            tryCatch({download.file(url = dt.retry$links.download[i], destfile = dt.retry$names.download[i])
            },
            error=function(cond) {
                return(NA)}
            )     
        }else{
            print(paste0(dt.retry$names.download[i], " : no PDF available"))  
        }
        
        Sys.sleep(runif(1, 0.5, 1.5))
    } 
}


#'## Timestamp (Retry Download End)
end.download <- Sys.time()
print(end.download)

#'## Duration (Retry Download)
end.download - begin.download



#'## Retry Result

files.pdf <- list.files(pattern = "\\.pdf",
                        ignore.case = TRUE)


#'### Successful during Retry

retry.success.names <- files.pdf[files.pdf %in% missing.names]
print(retry.success.names)

#'### Missing after Retry

retry.missing.names <- setdiff(retry.success.names,
                               missing.names)
print(retry.missing.names)



#'## Final Download Result

#+
#'### Number of Files to Download
download.expected.N <- dt[,.N]
print(download.expected.N)

#'### Number of Files Successfully Downloaded
files.pdf <- list.files(pattern = "\\.pdf",
                        ignore.case = TRUE)

download.success.N <- length(files.pdf)
print(download.success.N)

#'### Number of Missing Files
missing.N <- download.expected.N - download.success.N
print(missing.N)

#'### Names of Missing Files
missing.names <- setdiff(dt$names.download,
                         files.pdf)
print(missing.names)




#'# File Split Module

#'## Armed Activities Order
#' Note: this file contains the correct French document, but also an appended opinion in English, which is already correctly located in another file. Therefore the appended opinion is simply removed from the file.

filename <- "116-20161206-ORD-01-00-FR.pdf"

file.temp <- paste0(filename,
                    "-temp")

file.rename(filename, file.temp)

pdf_subset(file.temp, 1:5, filename)

unlink(file.temp)




#'## Case 146
#' **Note:** The files for the Advisory Opinion and appended opinions of Case 146 are all bilingual, including the supposedly monolingual versions. These need to be split into their component language versions. English is assumed to be on even pages for the majority opinion and on odd pages for the appended opinions. Both processes are looped in case further documents in need of splitting are discovered.


#+
#'### English on Even Pages

even.english <-  c("146-20120201-ADV-01-00-BI.pdf")

for (file in even.english){
    temp1 <- seq(1, pdf_length(file), 1)
    
    even <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) == 0]   
    even.name <- gsub("BI\\.pdf",
                      "EN\\.pdf",
                      file)               
    pdf_subset(file,
               pages = even,
               output = even.name)
    
    odd <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) != 0]    
    odd.name <- gsub("BI\\.pdf",
                     "FR\\.pdf",
                     file)   
    pdf_subset(file,
               pages = odd,
               output = odd.name)  
}


#'### English on Odd Pages

odd.english <- c("146-20120201-ADV-01-01-BI.pdf",
                 "146-20120201-ADV-01-02-BI.pdf")

for (file in odd.english){
    temp1 <- seq(1, pdf_length(file), 1)
    
    even <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) == 0]  
    even.name <- gsub("BI\\.pdf",
                      "FR\\.pdf",
                      file)   
    pdf_subset(file,
               pages = even,
               output = even.name)
    
    odd <- temp1[lapply(seq(1, max(temp1), 1), "%%", 2) != 0]   
    odd.name <- gsub("BI\\.pdf",
                     "EN\\.pdf",
                     file)  
    pdf_subset(file,
               pages = odd,
               output = odd.name)
}


#'### Delete Bilingual Files
unlink(even.english)
unlink(odd.english)




#'## Amity Treaty Order
#' Note: this file is bilingual. The English pages are removed manually.

filename <- "175-20210721-ORD-01-00-FR.pdf"

file.temp <- paste0(filename,
                    "-temp")

file.rename(filename, file.temp)

pdf_subset(file.temp, c(1:4, 6, 8), filename)

unlink(file.temp)





#'# Filename Enhancement Module
#' This module applies a number of enhancements to the filenames:
#' \begin{itemize}
#' \item Better separators
#' \item Case names
#' \item Applicant ISO codes
#' \item Respondent ISO codes
#' \item Stage of proceedings
#' \end{itemize}


filenames.original <- list.files(pattern = "\\.pdf")

#'## Enhance Syntax

filenames.enhanced1 <- gsub(paste0("([0-9]{3})", # var: caseno
                                   "-",
                                   "([0-9]{4})([0-9]{2})([0-9]{2})", # var: date
                                   "-",
                                   "([A-Z]{3})", # var: doctype
                                   "-",
                                   "([0-9]{2})", # var: collision
                                   "-",
                                   "([0-9]{2})", # var: opinion
                                   "-",
                                   "([A-Z]{2})"), # var: language
                            "\\1_\\2-\\3-\\4_\\5_\\6_\\7_\\8",
                            filenames.original)





#+
#'## Manual Coding


########## HAND CODING ####################
### - CASENAMES
### - Applicant Codes
### - Respondent Codes
### - Stage of Proceedings
############################################



#+
#'## Read Hand Coded Data
casenames <- fread("data/CD-ICJ_Source_CaseNames.csv",
                   header = TRUE)


#'## Add Hand Coded Data to Filenames
#' Case names, Applicant codes and Respondent codes have been hand coded and are added in this step.

caseno.pad <- formatC(casenames$caseno,
                      width = 3,
                      flag = "0")

case.header <- paste0("ICJ_",
                      caseno.pad,
                      "_",
                      casenames$casename_short,
                      "_")

filenames.enhanced2 <- mgsub(filenames.enhanced1,
                             paste0("^",
                                    caseno.pad,
                                    "\\_"),
                             case.header)



#'## Add Stage of Proceedings

stage <- fread("data/CD-ICJ_Source_Stages_Filenames.csv")



filenames.enhanced3 <- mgsub(filenames.enhanced2,
                             stage$old,
                             stage$new)

filenames.enhanced3 <- gsub("([0-9]{4}-[0-9]{2}-[0-9]{2}_[A-Z]{3}_[0-9]{2})(_[0-9]{2})",
                            "\\1_NA\\2",
                            filenames.enhanced3)





#'\newpage
#'## REGEX VALIDATION 2: Strictly Validate Naming Scheme against Codebook Schema
#' Test strict compliance with variable types described in Codebook. The result should be an empty character vector!


#+
#'### Execute Validation

regex.test2 <- grep(paste0("^ICJ", # var: court
                           "_",
                           "[0-9]{3}", # var: caseno
                           "_",
                           "[A-Za-z0-9\\-]*", # var: shortname
                           "_",
                           "[A-Z\\-]*", # var: applicant
                           "_",
                           "[A-Z\\-]*", # var: respondent
                           "_",
                           "[0-9]{4}-[0-9]{2}-[0-9]{2}", # var: date
                           "_",
                           "(JUD|ADV|ORD)", # var: doctype
                           "_",
                           "[0-9]{2}", # var: collision
                           "_",
                           "(NA|PO|ME|IN|CO)", # var: stage
                           "_",
                           "[0-9]{2}", # var: opinion
                           "_",
                           "(EN|FR)", # var: language
                           ".pdf$"), # file extension
                    filenames.enhanced3,
                    value = TRUE,
                    invert = TRUE)



#'### Results of Validation
print(regex.test2)


#'### Stop Script on Failure

if (length(regex.test2) != 0){
    stop("REGEX VALIDATION 2 FAILED: FILE NAMES NOT IN COMPLIANCE WITH CODEBOOK SCHEMA!")
    }




#'## Execute Rename
#+ results = "hide"

file.rename(filenames.original,
            filenames.enhanced3)




#'# Detect Missing Counterparts for each Language Variant

files.en <- list.files(pattern = "EN\\.pdf")
files.fr <- list.files(pattern = "FR\\.pdf")


#'## Difference between French and English File Lists
abs(length(files.en) - length(files.fr))


#'## Show Missing French Documents
files.fr.temp <- gsub("FR\\.pdf",
                      "EN\\.pdf",
                      files.fr)

frenchmissing <- setdiff(files.en,
                         files.fr.temp)

frenchmissing <- gsub("EN\\.pdf",
                      "FR\\.pdf",
                      frenchmissing)

print(frenchmissing)


#'## Show Missing English Documents
files.en.temp <- gsub("EN\\.pdf",
                      "FR\\.pdf",
                      files.en)

englishmissing <- setdiff(files.fr,
                          files.en.temp)

englishmissing <- gsub("FR\\.pdf",
                       "EN\\.pdf",
                       englishmissing)

print(englishmissing)








#'# Text Extraction Module


#'## Define Set of Files to Process
files.pdf <- list.files(pattern = "\\.pdf$",
                        ignore.case = TRUE)


#'## Number of Files to Process
length(files.pdf)


#'## Show Function: f.dopar.pagenums
#+ results = "asis"
print(f.dopar.pagenums)


#'## Count Pages
f.dopar.pagenums(files.pdf,
                 sum = TRUE,
                 threads = fullCores)


#'## Show Function: f.dopar.pdfextract
#+ results = "asis"
print(f.dopar.pdfextract)


#'## Extract Text
result <- f.dopar.pdfextract(files.pdf,
                             threads = fullCores)

 



#'## Copy and Move EXTRACTED TXT Files
#' This step copies all extracted TXT files from 2005 and later, which are assumed to be born-digital, to the BEST variant TXT folder. It further moves all TXT files to the "EXTRACTED" folder.

#+ results = "hide"
txt.best.en <- list.files(pattern = "_(200[5-9]|201[0-9]|202[0-5])-.*EN\\.txt")
txt.best.fr <- list.files(pattern = "_(200[5-9]|201[0-9]|202[0-5])-.*FR\\.txt")

file_copy(txt.best.en,
          "EN_TXT_BEST_FULL")
file_copy(txt.best.fr,
          "FR_TXT_BEST_FULL")

txt.extracted.en <- list.files(pattern = "EN\\.txt")
txt.extracted.fr <- list.files(pattern = "FR\\.txt")

file_move(txt.extracted.en,
          "EN_TXT_EXTRACTED_FULL")
file_move(txt.extracted.fr,
          "FR_TXT_EXTRACTED_FULL")







#'# Tesseract OCR Module

#+
#'## Mark Files for OCR
#' Only files which were published in 2004 or earlier are marked for optical character recognition (OCR) processing. Files from 2005 onwards are assumed to be born-digital and of perfect quality.

#+ results = "hide"
files.pdf.en <- list.files(pattern = "EN\\.pdf")
files.pdf.fr <- list.files(pattern = "FR\\.pdf")

files.ocr.en <- list.files(pattern = "_(19[4-8][0-9]|199[0-9]|200[0-4])-.*EN\\.pdf")
files.ocr.fr <- list.files(pattern = "_(19[4-8][0-9]|199[0-9]|200[0-4])-.*FR\\.pdf")


#'## Copy and Move Born-Digital Files

files.pdf.best.en <- setdiff(files.pdf.en,
                             files.ocr.en)

files.pdf.best.fr <- setdiff(files.pdf.fr,
                             files.ocr.fr)

file_copy(files.pdf.best.en,
          "EN_PDF_BEST_FULL")
file_copy(files.pdf.best.fr,
          "FR_PDF_BEST_FULL")


file_move(files.pdf.best.en,
          "EN_PDF_ORIGINAL_FULL")
file_move(files.pdf.best.fr,
          "FR_PDF_ORIGINAL_FULL")




#'## Show Function: f.dopar.pdfocr
#+ results = "asis"
print(f.dopar.pdfocr)


#'## English

#+
#'### Number of English Documents to Process
length(files.ocr.en)

#'### Number of English Pages to Process
f.dopar.pagenums(files.ocr.en,
                 sum = TRUE,
                 threads = fullCores)



#'### Run OCR on English Documents
#' **Note:** Training data is set to include both English and French. Lengthy quotations in a non-dominant language are common in international law. Order in language setting matters and for English documents "eng" is set as the primary training data.

result <- f.dopar.pdfocr(files.ocr.en,
                         dpi = ocr.dpi,
                         lang = "eng+fra",
                         output = "pdf txt",
                         jobs = ocrCores)




#'## French


#+
#'### Number of French Documents to Process
length(files.ocr.fr)



#'### Number of French Pages to Process
f.dopar.pagenums(files.ocr.fr,
                 sum = TRUE,
                 threads = fullCores)



#'### Run OCR on French Documents
#' **Note:** Training data is set to include both French and English. Lengthy quotations in a non-dominant language are common in international law. Order in language setting matters and for French documents "fra" is set as the primary training data.

result <- f.dopar.pdfocr(files.ocr.fr,
                         dpi = ocr.dpi,
                         lang = "fra+eng",
                         output = "pdf txt",
                         jobs = ocrCores)






#'## Rename Files

#+ results = "hide"
files.pdf <- list.files(pattern = "\\.pdf$")

files.pdf.enhanced <- gsub("_TESSERACT.pdf",
                           "_ENHANCED.pdf",
                           files.pdf)

file.rename(files.pdf,
            files.pdf.enhanced)


#+ results = "hide"
files.txt <- list.files(pattern = "\\.txt$")

files.txt.new <- gsub("_TESSERACT.txt",
                      ".txt",
                      files.txt)

file.rename(files.txt,
            files.txt.new)




#'## Copy and Move TXT Files

files.ocr.txt.en <- list.files(pattern = "EN\\.txt")
files.ocr.txt.fr <- list.files(pattern = "FR\\.txt")

file_copy(files.ocr.txt.en,
          "EN_TXT_BEST_FULL")
file_copy(files.ocr.txt.fr,
          "FR_TXT_BEST_FULL")

file_move(files.ocr.txt.en,
          "EN_TXT_TESSERACT_max2004")
file_move(files.ocr.txt.fr,
          "FR_TXT_TESSERACT_max2004")




#'## Copy and Move PDF Files

files.ocr.pdf.enhanced.en <- list.files(pattern = "EN_ENHANCED\\.pdf")
files.ocr.pdf.enhanced.fr <- list.files(pattern = "FR_ENHANCED\\.pdf")

files.ocr.pdf.original.en <- list.files(pattern = "EN\\.pdf")
files.ocr.pdf.original.fr <- list.files(pattern = "FR\\.pdf")


file_copy(files.ocr.pdf.enhanced.en,
          "EN_PDF_BEST_FULL")
file_copy(files.ocr.pdf.enhanced.fr,
          "FR_PDF_BEST_FULL")

file_move(files.ocr.pdf.enhanced.en,
          "EN_PDF_ENHANCED_max2004")
file_move(files.ocr.pdf.enhanced.fr,
          "FR_PDF_ENHANCED_max2004")

file_move(files.ocr.pdf.original.en,
          "EN_PDF_ORIGINAL_FULL")
file_move(files.ocr.pdf.original.fr,
          "FR_PDF_ORIGINAL_FULL")







#'# Create Majority-Only Variant

majonly.en <- list.files("EN_PDF_BEST_FULL",
                         full.names = TRUE,
                         pattern = "00_EN")

majonly.fr <- list.files("FR_PDF_BEST_FULL",                      
                         full.names = TRUE,
                         pattern = "00_FR")

file_copy(majonly.en,
          "EN_PDF_BEST_MajorityOpinions")
file_copy(majonly.fr,
          "FR_PDF_BEST_MajorityOpinions")







#'# Read in TXT Files

#'## Define Variable Names

names.variables <- c("court",
                     "caseno",
                     "shortname",
                     "applicant",
                     "respondent",
                     "date",
                     "doctype",
                     "collision",
                     "stage",
                     "opinion",
                     "language")



#'## BEST Variants

#'### English

data.best.en <- readtext("EN_TXT_BEST_FULL/*.txt",
                         docvarsfrom = "filenames", 
                         docvarnames = names.variables,
                         dvsep = "_", 
                         encoding = "UTF-8")

#'### French

data.best.fr <- readtext("FR_TXT_BEST_FULL/*.txt",
                         docvarsfrom = "filenames", 
                         docvarnames = names.variables,
                         dvsep = "_", 
                         encoding = "UTF-8")


#'## EXTRACTED Variants

#'### English

data.extracted.en <- readtext("EN_TXT_EXTRACTED_FULL/*.txt",
                              docvarsfrom = "filenames", 
                              docvarnames =  names.variables,
                              dvsep = "_", 
                              encoding = "UTF-8")



#'### French

data.extracted.fr <- readtext("FR_TXT_EXTRACTED_FULL/*.txt",
                              docvarsfrom = "filenames", 
                              docvarnames =  names.variables,
                              dvsep = "_", 
                              encoding = "UTF-8")


#'## Convert to Data Tables

setDT(data.best.en)
setDT(data.best.fr)
setDT(data.extracted.en)
setDT(data.extracted.fr)



#'# Clean Texts


#+
#'## Remove Hyphenation across Linebreaks
#' Hyphenation across linebreaks is a serious issue in longer texts. Hyphenated words are often not recognized as a single token by standard tokenization. The result is two unique and non-expressive tokens instead of a single, expressive token. This section removes these hyphenations.


#+
#'### Show Function: f.hyphen.remove

print(f.hyphen.remove)

#'### Execute Function

data.best.en[, text := lapply(.(text), f.hyphen.remove)]
data.best.fr[, text := lapply(.(text), f.hyphen.remove)]

data.extracted.en[, text := lapply(.(text), f.hyphen.remove)]
data.extracted.fr[, text := lapply(.(text), f.hyphen.remove)]


#'## Replace Special Characters
#' This section replaces special characters with their closest equivalents in the Latin alphabet, as some R functions have difficulties processing the originals. These characters usually occur due to OCR mistakes.

#+
#'### Show Function: f.special.replace

print(f.special.replace)

#'### Execute Function

data.best.en[, text := lapply(.(text), f.special.replace)]
data.best.fr[, text := lapply(.(text), f.special.replace)]

data.extracted.en[, text := lapply(.(text), f.special.replace)]
data.extracted.fr[, text := lapply(.(text), f.special.replace)]







#'# OCR Quality Control Module
#' This module measures the quality of the new Tesseract-generated OCR text against the OCR text provided by the ICJ, which was extracted from the original documents.
#'
#' Only documents from 2004 or earlier will be compared. This provides a more accurate measurement of the relative quality of the different OCR processes than if born-digital documents were to be included.


#+
#'## Create Corpora

corpus.en.b <- corpus(data.best.en)
corpus.en.e <- corpus(data.extracted.en)

corpus.fr.b <- corpus(data.best.fr)
corpus.fr.e <- corpus(data.extracted.fr)


#'## Subset to 2004 and earlier

corpus.en.b.2004  <- corpus_subset(corpus.en.b, date < 2005)
corpus.en.e.2004  <- corpus_subset(corpus.en.e, date < 2005)

corpus.fr.b.2004  <- corpus_subset(corpus.fr.b, date < 2005)
corpus.fr.e.2004  <- corpus_subset(corpus.fr.e, date < 2005)


#'## Show Function: f.token.processor

print(f.token.processor)

#'## Tokenize

quanteda_options(tokens_locale = "en") # Set Locale for Tokenization

tokens.en.b.2004 <- f.token.processor(corpus.en.b.2004)
tokens.en.e.2004 <- f.token.processor(corpus.en.e.2004)

quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization

tokens.fr.b.2004 <- f.token.processor(corpus.fr.b.2004)
tokens.fr.e.2004 <- f.token.processor(corpus.fr.e.2004)


#'## Create Document-Feature-Matrices

dfm.en.b.2004 <- dfm(tokens.en.b.2004)
dfm.en.e.2004 <- dfm(tokens.en.e.2004)

dfm.fr.b.2004 <- dfm(tokens.fr.b.2004)
dfm.fr.e.2004 <- dfm(tokens.fr.e.2004)



#'## Features Reduction
#' **Note:** This is the number of features which have been saved by using advanced OCR in comparison to the OCR used by the ICJ.


feat.languages <- c("English",
                    "French")

feat.extracted <- c(nfeat(dfm.en.e.2004),
                    nfeat(dfm.fr.e.2004))


feat.tesseract <- c(nfeat(dfm.en.b.2004),
                    nfeat(dfm.fr.b.2004))



feat.reduction.abs <- feat.extracted - feat.tesseract

feat.reduction.rel.pct <- (1 - (feat.tesseract / feat.extracted)) * 100


dt.ocrquality <- data.table(feat.languages,
                            feat.extracted,
                            feat.tesseract,
                            feat.reduction.abs,
                            paste(round(feat.reduction.rel.pct, 2), "%"))



kable(dt.ocrquality,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      col.names = c("Language",
                    "Extracted Features",
                    "Tesseract Features",
                    "Difference (abs)",
                    "Difference (pct)"))



#'# Language Purity Module
#' This module analyzes the n-gram patterns of each document with **textcat** to detect the most likely language. Only English and French are considered. This is to ensure maximum monolinguality of documents, which is an advantage in Natural Language Processing.



#+
#'## Limit Detection to English and French

lang.profiles <- TC_byte_profiles[names(TC_byte_profiles) %in% c("english",
                                                                 "french")]


#'## Automatic Language Detection

data.best.en$textcat <- textcat(data.best.en$text,
                                p = lang.profiles)

data.best.fr$textcat <- textcat(data.best.fr$text,
                                p = lang.profiles)


#'## Detected Languages

#' **Note:** Should only read 'english'
unique(data.best.en$textcat)

#' **Note:** Should only read 'french'
unique(data.best.fr$textcat)



#'## Show Mismatches
#' Print files which failed to match the language specified in metadata.

langtest.fail.en <- data.best.en[textcat != "english", .(doc_id, textcat)]
print(langtest.fail.en)

langtest.fail.fr <- data.best.fr[textcat != "french", .(doc_id, textcat)]
print(langtest.fail.fr)


#'## Final Note: Human Review of Mismatches
#' All documents flagged by textcat were reviewed and appropriate remedies devised. Some files were deleted from the corpus if no authentic language variant could be found. Monolingual files for case 146 are now generated from the bilingual originals. See the download section for details.





#+
#'# Add and Delete Variables

#+
#'## Delete Textcat Classifications

data.best.en$textcat <- NULL
data.best.fr$textcat <- NULL


#'## Add Variable "year"

data.best.en$year <- year(data.best.en$date)
data.best.fr$year <- year(data.best.fr$date)


#'## Add Variable "minority"
#' "0" indicates a majority opinion, "1" a minority opinion.

data.best.en$minority <- (data.best.en$opinion != 0) * 1
data.best.fr$minority <- (data.best.fr$opinion != 0) * 1


#'## Add Variable "fullname"

#+
#'### Read Hand Coded Data
casenames <- fread("data/CD-ICJ_Source_CaseNames.csv",
                   header = TRUE)


#'### Create Variable

data.best.en$fullname <- casenames$casename_full[match(data.best.en$caseno,
                                                       casenames$caseno)]

data.best.fr$fullname <- casenames$casename_full[match(data.best.fr$caseno,
                                                       casenames$caseno)]





#'## Add Variable "applicant_region"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-ICJ_Source_CountryCodes.csv")





#'### Merge Regions for English Version

applicant_region <- data.best.en$applicant

applicant_region <- gsub("CARAT|ECOSOC|IFAD|IMO|UNESCO|UNGA|UNSC|WHO",
                         "NA",
                         applicant_region)

applicant_region <- gsub("-",
                         "|",
                         applicant_region)


applicant_region <- mgsub(applicant_region,
                          countrycodes$ISO3,
                          countrycodes$region)

data.best.en$applicant_region <- applicant_region



#'### Merge Regions for French Version

applicant_region <- data.best.fr$applicant

applicant_region <- gsub("CARAT|ECOSOC|IFAD|IMO|UNESCO|UNGA|UNSC|WHO",
                         "NA",
                         applicant_region)

applicant_region <- gsub("-",
                         "|",
                         applicant_region)


applicant_region <- mgsub(applicant_region,
                          countrycodes$ISO3,
                          countrycodes$region)

data.best.fr$applicant_region <- applicant_region



#'## Add Variable "respondent_region"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-ICJ_Source_CountryCodes.csv")


#'### Merge Regions for English Version

respondent_region <- data.best.en$respondent

respondent_region <- gsub("-",
                          "|",
                          respondent_region)

respondent_region <- mgsub(respondent_region,
                           countrycodes$ISO3,
                           countrycodes$region)

data.best.en$respondent_region <- respondent_region



#'### Merge Regions for French Version


respondent_region <- data.best.fr$respondent

respondent_region <- gsub("-",
                          "|",
                          respondent_region)

respondent_region <- mgsub(respondent_region,
                           countrycodes$ISO3,
                           countrycodes$region)

data.best.fr$respondent_region <- respondent_region





#'## Add Variable "applicant_subregion"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-ICJ_Source_CountryCodes.csv")


#'### Merge Subregions for English Version

applicant_subregion <- data.best.en$applicant

applicant_subregion <- gsub("CARAT|ECOSOC|IFAD|IMO|UNESCO|UNGA|UNSC|WHO",
                            "NA",
                            applicant_subregion)

applicant_subregion <- gsub("-",
                            "|",
                            applicant_subregion)


applicant_subregion <- mgsub(applicant_subregion,
                             countrycodes$ISO3,
                             countrycodes$subregion)

data.best.en$applicant_subregion <- applicant_subregion



#'### Merge Subregions for French Version

applicant_subregion <- data.best.fr$applicant

applicant_subregion <- gsub("CARAT|ECOSOC|IFAD|IMO|UNECO|UNGA|UNSC|WHO",
                            "NA",
                            applicant_subregion)

applicant_subregion <- gsub("-",
                            "|",
                            applicant_subregion)


applicant_subregion <- mgsub(applicant_subregion,
                             countrycodes$ISO3,
                             countrycodes$subregion)

data.best.fr$applicant_subregion <- applicant_subregion



#'## Add Variable "respondent_subregion"



#+
#'### Read Hand Coded Data

countrycodes <- fread("data/CD-ICJ_Source_CountryCodes.csv")


#'### Merge Subregions for English Version

respondent_subregion <- data.best.en$respondent

respondent_subregion <- gsub("-",
                             "|",
                             respondent_subregion)

respondent_subregion <- mgsub(respondent_subregion,
                              countrycodes$ISO3,
                              countrycodes$subregion)

data.best.en$respondent_subregion <- respondent_subregion



#'### Merge Subregions for French Version


respondent_subregion <- data.best.fr$respondent

respondent_subregion <- gsub("-",
                             "|",
                             respondent_subregion)

respondent_subregion <- mgsub(respondent_subregion,
                              countrycodes$ISO3,
                              countrycodes$subregion)

data.best.fr$respondent_subregion <- respondent_subregion






#'## Add Variable "doi_concept"

data.best.en$doi_concept <- rep(doi.concept,
                                data.best.en[,.N])

data.best.fr$doi_concept <- rep(doi.concept,
                                data.best.fr[,.N])

#'## Add Variable "doi_version"

data.best.en$doi_version <- rep(doi.version,
                                data.best.en[,.N])

data.best.fr$doi_version <- rep(doi.version,
                                data.best.fr[,.N])


#'## Add Variable "version"

data.best.en$version <- as.character(rep(datestamp,
                                         data.best.en[,.N]))

data.best.fr$version <- as.character(rep(datestamp,
                                         data.best.fr[,.N]))


#'## Add Variable "license"

data.best.en$license <- as.character(rep(license,
                                         data.best.en[,.N]))

data.best.fr$license <- as.character(rep(license,
                                         data.best.fr[,.N]))







#'# Frequency Tables
#' Frequency tables are a very useful tool for checking the plausibility of categorical variables and detecting anomalies in the data. This section will calculate frequency tables for all variables of interest.

#+
#'## Show Function: f.fast.freqtable

#+ results = "asis"
print(f.fast.freqtable)


#+
#'## English Corpus

#+
#'### Variables to Ignore
print(freq.var.ignore)

#'### Variables to Analyze
varlist <- names(data.best.en)

varlist <- setdiff(varlist,
                   freq.var.ignore)

print(varlist)


#'### Construct Frequency Tables

prefix <- paste0(datashort,
                 "_EN_01_FrequencyTable_var-")


#+ results = "asis"
f.fast.freqtable(data.best.en,
                 varlist = varlist,
                 sumrow = TRUE,
                 output.list = FALSE,
                 output.kable = TRUE,
                 output.csv = TRUE,
                 outputdir = outputdir,
                 prefix = prefix,
                 align = c("p{5cm}",
                           rep("r", 4)))




#'\newpage
#'## French Corpus

#+
#'### Variables to Ignore
print(freq.var.ignore)

#'### Variables to Analyze

varlist <- names(data.best.fr)

varlist <- setdiff(varlist,
                   freq.var.ignore)

print(varlist)




#'### Construct Frequency Tables

prefix <- paste0(datashort,
                 "_FR_01_FrequencyTable_var-")


#+ results = "asis"
f.fast.freqtable(data.best.fr,
                 varlist = varlist,
                 sumrow = TRUE,
                 output.list = FALSE,
                 output.kable = TRUE,
                 output.csv = TRUE,
                 outputdir = outputdir,
                 prefix = prefix,
                 align = c("p{5cm}",
                           rep("r", 4)))











#'# Visualize Frequency Tables

#+
#'## Load Tables

prefix.en <- paste0("ANALYSIS/",
                    datashort,
                    "_EN_01_FrequencyTable_var-")

prefix.fr <- paste0("ANALYSIS/",
                    datashort,
                    "_FR_01_FrequencyTable_var-")


table.en.doctype <- fread(paste0(prefix.en,
                                 "doctype.csv"))

table.en.opinion <- fread(paste0(prefix.en,
                                 "opinion.csv"))

table.en.year <- fread(paste0(prefix.en,
                              "year.csv"))


table.fr.doctype <- fread(paste0(prefix.fr,
                                 "doctype.csv"))

table.fr.opinion <- fread(paste0(prefix.fr,
                                 "opinion.csv"))

table.fr.year <- fread(paste0(prefix.fr,
                              "year.csv"))







#'\newpage
#'## Doctype

#+
#'### English

freqtable <- table.en.doctype[-.N]


#+ CD-ICJ_EN_02_Barplot_Doctype, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(doctype,
                             -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black",
             width = 0.4) +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Documents per Document Type"),
        caption = paste("DOI:",
                        doi.version),
        x = "Document Type",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )


#'\newpage
#'### French

freqtable <- table.fr.doctype[-.N]


#+ CD-ICJ_FR_02_Barplot_Doctype, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(doctype,
                             -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black",
             width = 0.4) +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Documents per Document Type"),
        caption = paste("DOI:",
                        doi.version),
        x = "Document Type",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )


#'\newpage
#'## Opinion

#+
#'### English

freqtable <- table.en.opinion[-.N]

#+ CD-ICJ_EN_03_Barplot_Opinion, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(opinion,
                             -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black") +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Documents per Opinion Number"),
        caption = paste("DOI:",
                        doi.version),
        x = "Opinion Number",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )


#'\newpage
#'### French

freqtable <- table.fr.opinion[-.N]

#+ CD-ICJ_FR_03_Barplot_Opinion, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = reorder(opinion, -N),
                 y = N),
             stat = "identity",
             fill = "black",
             color = "black") +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Documents per Opinion Number"),
        caption = paste("DOI:",
                        doi.version),
        x = "Opinon Number",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )



#'\newpage
#'## Year

#+
#'### English

freqtable <- table.en.year[-.N][,lapply(.SD, as.numeric)]

#+ CD-ICJ_EN_04_Barplot_Year, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = year,
                 y = N),
             stat = "identity",
             fill = "black") +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Documents per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 16),
        plot.title = element_text(size = 16,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )



#'\newpage
#'### French

freqtable <- table.fr.year[-.N][,lapply(.SD, as.numeric)]

#+ CD-ICJ_FR_04_Barplot_Year, fig.height = 6, fig.width = 9
ggplot(data = freqtable) +
    geom_bar(aes(x = year,
                 y = N),
             stat = "identity",
             fill = "black") +
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Documents per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Documents"
    )+
    theme(
        text = element_text(size = 16),
        plot.title = element_text(size = 16,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )






#'# Summary Statistics


#+
#'## Linguistic Metrics
#' For the text of each document the number of characters, tokens, types and sentences will be calculated.


#+
#'### Show Function: f.lingsummarize.iterator
#+ results = "asis"
print(f.lingsummarize.iterator)


#'### Calculate Linguistic Metrics

quanteda_options(tokens_locale = "en") # Set Locale for Tokenization

summary.corpus.en <- f.lingsummarize.iterator(data.best.en,
                                          threads = fullCores,
                                          chunksize = 1)


quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization

summary.corpus.fr <- f.lingsummarize.iterator(data.best.fr,
                                          threads = fullCores,
                                          chunksize = 1)


#'### Add Linguistic Metrics to Full Corpora

data.best.en <- cbind(data.best.en,
                      summary.corpus.en)

data.best.fr <- cbind(data.best.fr,
                      summary.corpus.fr)


#'### Create Metadata-only Variants

meta.best.en <- data.best.en[, !"text"]
meta.best.fr <- data.best.fr[, !"text"]





#+
#'### Calculate Summaries: English

dt.summary.ling <- meta.best.en[, lapply(.SD,
                                         function(x)unclass(summary(x))),
                                .SDcols = c("nchars",
                                            "ntokens",
                                            "ntypes",
                                            "nsentences")]


dt.sums.ling <- meta.best.en[,
                             lapply(.SD, sum),
                             .SDcols = c("nchars",
                                         "ntokens",
                                         "ntypes",
                                         "nsentences")]

quanteda_options(tokens_locale = "en") # Set Locale for Tokenization

tokens.temp <- tokens(corpus(data.best.en),
                      what = "word",
                      remove_punct = FALSE,
                      remove_symbols = FALSE,
                      remove_numbers = FALSE,
                      remove_url = FALSE,
                      remove_separators = TRUE,
                      split_hyphens = FALSE,
                      include_docvars = FALSE,
                      padding = FALSE
                      )

dt.sums.ling$ntypes <- nfeat(dfm(tokens.temp))




dt.stats.ling <- rbind(dt.sums.ling,
                       dt.summary.ling)

dt.stats.ling <- transpose(dt.stats.ling,
                           keep.names = "names")

setnames(dt.stats.ling, c("Variable",
                          "Total",
                          "Min",
                          "Quart1",
                          "Median",
                          "Mean",
                          "Quart3",
                          "Max"))

#'\newpage
#'### Show Summaries: English

kable(dt.stats.ling,
      format.args = list(big.mark = ","),
      format = "latex",
      booktabs = TRUE)


#'### Write Summaries to Disk: English

fwrite(dt.stats.ling,
       paste0(outputdir,
              datashort,
              "_EN_00_CorpusStatistics_Summaries_Linguistic.csv"),
       na = "NA")




#'\newpage
#'### Calculate Summaries: French

dt.summary.ling <- meta.best.fr[, lapply(.SD,
                                         function(x)unclass(summary(x))),
                                .SDcols = c("nchars",
                                            "ntokens",
                                            "ntypes",
                                            "nsentences")]


dt.sums.ling <- meta.best.fr[,
                             lapply(.SD, sum),
                             .SDcols = c("nchars",
                                         "ntokens",
                                         "ntypes",
                                         "nsentences")]


quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization

tokens.temp <- tokens(corpus(data.best.fr),
                      what = "word",
                      remove_punct = FALSE,
                      remove_symbols = FALSE,
                      remove_numbers = FALSE,
                      remove_url = FALSE,
                      remove_separators = TRUE,
                      split_hyphens = FALSE,
                      include_docvars = FALSE,
                      padding = FALSE
                      )

dt.sums.ling$ntypes <- nfeat(dfm(tokens.temp))




dt.stats.ling <- rbind(dt.sums.ling,
                       dt.summary.ling)

dt.stats.ling <- transpose(dt.stats.ling,
                           keep.names = "names")

setnames(dt.stats.ling, c("Variable",
                          "Total",
                          "Min",
                          "Quart1",
                          "Median",
                          "Mean",
                          "Quart3",
                          "Max"))


#'\newpage
#'### Show Summaries: French

kable(dt.stats.ling,
      format.args = list(big.mark = ","),
      format = "latex",
      booktabs = TRUE)


#'### Write Summaries to Disk: French

fwrite(dt.stats.ling,
       paste0(outputdir,
              datashort,
              "_FR_00_CorpusStatistics_Summaries_Linguistic.csv"),
       na = "NA")










#'\newpage
#'## Distributions

#+
#'### Tokens per Year: English

tokens.year.en <- meta.best.en[,
                               sum(ntokens),
                               by = "year"]



#+ CD-ICJ_EN_05_TokensPerYear, fig.height = 6, fig.width = 9
print(
    ggplot(data = tokens.year.en,
           aes(x = year,
               y = V1))+
    geom_bar(stat = "identity",
             fill = "black")+
    scale_y_continuous(labels = comma)+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Number of Tokens per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Tokens"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold")
    )
)






#'\newpage
#'### Tokens per Year: French

tokens.year.fr <- meta.best.fr[,
                               sum(ntokens),
                               by = "year"]


#+ CD-ICJ_FR_05_TokensPerYear, fig.height = 6, fig.width = 9
print(
    ggplot(data = tokens.year.fr,
           aes(x = year,
               y = V1))+
    geom_bar(stat = "identity",
             fill = "black")+
    scale_y_continuous(labels = comma)+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Number of Tokens per Year"),
        caption = paste("DOI:",
                        doi.version),
        x = "Year",
        y = "Tokens"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold")
    )
)






#'\newpage
#+
#'### Density: Characters

#+ CD-ICJ_EN_06_Density_Characters, fig.height = 6, fig.width = 9
ggplot(data = meta.best.en) +
    geom_density(aes(x = nchars),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Distribution of Document Length (Characters)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Characters",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#+ CD-ICJ_FR_06_Density_Characters, fig.height = 6, fig.width = 9
ggplot(data = meta.best.fr) +
    geom_density(aes(x = nchars),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Distribution of Document Length (Characters)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Characters",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#'### Density: Tokens

#+ CD-ICJ_EN_07_Density_Tokens, fig.height = 6, fig.width = 9
ggplot(data = meta.best.en) +
    geom_density(aes(x = ntokens),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Distribution of Document Length (Tokens)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Tokens",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#+ CD-ICJ_FR_07_Density_Tokens, fig.height = 6, fig.width = 9
ggplot(data = meta.best.fr) +
    geom_density(aes(x = ntokens),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Distribution of Document Length (Tokens)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Tokens",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )





#'\newpage
#'### Density: Types

#+ CD-ICJ_EN_08_Density_Types, fig.height = 6, fig.width = 9
ggplot(data = meta.best.en) +
    geom_density(aes(x = ntypes),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Distribution of Document Length (Types)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Types",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )



#'\newpage
#+ CD-ICJ_FR_08_Density_Types, fig.height = 6, fig.width = 9
ggplot(data = meta.best.fr) +
    geom_density(aes(x = ntypes),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Distribution of Document Length (Types)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Types",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#'### Density: Sentences

#+ CD-ICJ_EN_09_Density_Sentences, fig.height = 6, fig.width = 9
ggplot(data = meta.best.en) +
    geom_density(aes(x = nsentences),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Distribution of Document Length (Sentences)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Sentences",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage
#+ CD-ICJ_FR_09_Density_Sentences, fig.height = 6, fig.width = 9
ggplot(data = meta.best.fr) +
    geom_density(aes(x = nsentences),
                 fill = "black") +
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Distribution of Document Length (Sentences)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Sentences",
        y = "Density"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )



#'\newpage
#'### All Distributions of Linguistic Metrics
#' When plotting a boxplot on a logarithmic scale the standard geom_boxplot() function from ggplot2 incorrectly performs the statistical transformation first before calculating the boxplot statistics. While median and quartiles are based on ordinal position the inter-quartile range differs depending on when statistical transformation is performed.
#'
#' Solutions are based on this SO question: https://stackoverflow.com/questions/38753628/ggplot-boxplot-length-of-whiskers-with-logarithmic-axis

print(f.boxplot.body)
print(f.boxplot.outliers)



dt.allmetrics.en <- melt(summary.corpus.en,
                         measure.vars = rev(c("nchars",
                                              "ntokens",
                                              "ntypes",
                                              "nsentences")))

#'\newpage
#+ CD-ICJ_EN_10_Distributions_LinguisticMetrics, fig.height = 10, fig.width = 8.3
ggplot(dt.allmetrics.en, aes(x = value,
                             y = variable))+
    geom_violin()+
    stat_summary(fun.data = f.boxplot.body,
                 geom = "errorbar",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.body,
                 geom = "boxplot",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.outliers,
                 geom = "point",
                 size =  0.5,
                 alpha = 0.1)+
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    scale_y_discrete(labels = rev(c("Characters",
                                    "Tokens",
                                    "Types",
                                    "Sentences")))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Distributions of Document Length"),
        caption = paste("DOI:",
                        doi.version),
        x = "Value",
        y = "Linguistic Metric"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )




#'\newpage

dt.allmetrics.fr <- melt(summary.corpus.fr,
                         measure.vars = rev(c("nchars",
                                             "ntokens",
                                             "ntypes",
                                             "nsentences")))

#+ CD-ICJ_FR_10_Distributions_LinguisticMetrics, fig.height = 10, fig.width = 8.3
ggplot(dt.allmetrics.fr, aes(x = value,
                             y = variable)) +
    geom_violin()+
    stat_summary(fun.data = f.boxplot.body,
                 geom = "errorbar",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.body,
                 geom = "boxplot",
                 width = 0.1) +
    stat_summary(fun.data = f.boxplot.outliers,
                 geom = "point",
                 size =  0.5,
                 alpha = 0.1)+
    scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))+
    annotation_logticks(sides = "b")+
    coord_cartesian(xlim = c(1, 10^6))+
    scale_y_discrete(labels = rev(c("Characters",
                                    "Tokens",
                                    "Types",
                                    "Sentences")))+
    theme_bw() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Distributions of Document Length"),
        caption = paste("DOI:",
                        doi.version),
        x = "Value",
        y = "Linguistic Metric"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        plot.margin = margin(10, 20, 10, 10)
    )









#'\newpage
#'## Number of Majority Opinions

#+
#'### English

dt.maj.disaggregated <- meta.best.en[opinion == 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.maj.disaggregated$N))

dt.maj.disaggregated <- rbind(dt.maj.disaggregated,
                              sumrow,
                              use.names = FALSE)



kable(dt.maj.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.maj.disaggregated,
       paste0(outputdir,
              datashort,
              "_EN_00_CorpusStatistics_Summaries_Majority.csv"),
       na = "NA")



#'\newpage
#'### French

dt.maj.disaggregated <- meta.best.fr[opinion == 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.maj.disaggregated$N))

dt.maj.disaggregated <- rbind(dt.maj.disaggregated,
                              sumrow,
                              use.names = FALSE)


kable(dt.maj.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.maj.disaggregated,
       paste0(outputdir,
              datashort,
              "_FR_00_CorpusStatistics_Summaries_Majority.csv"),
       na = "NA")



#'\newpage
#'## Number of Minority Opinions

#+
#'### English

dt.min.disaggregated <- meta.best.en[opinion > 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.min.disaggregated$N))

dt.min.disaggregated <- rbind(dt.min.disaggregated,
                              sumrow,
                              use.names = FALSE)



kable(dt.min.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.min.disaggregated,
       paste0(outputdir,
              datashort,
              "_EN_00_CorpusStatistics_Summaries_Minority.csv"),
       na = "NA")





#'\newpage
#'### French

dt.min.disaggregated <- meta.best.fr[opinion > 0,
                                          .N,
                                          keyby = "doctype"]

sumrow <- data.table("Total",
                     sum(dt.min.disaggregated$N))

dt.min.disaggregated <- rbind(dt.min.disaggregated,
                              sumrow,
                              use.names = FALSE)


kable(dt.min.disaggregated,
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)


fwrite(dt.min.disaggregated,
       paste0(outputdir,
              datashort,
              "_FR_00_CorpusStatistics_Summaries_Minority.csv"),
       na = "NA")







#'## Year Range

summary(meta.best.en$year) # English
summary(meta.best.fr$year) # French



#'## Date Range

meta.best.en$date <- as.Date(meta.best.en$date)
meta.best.fr$date <- as.Date(meta.best.fr$date)

summary(meta.best.en$date) # English
summary(meta.best.fr$date) # French




#'# Test and Sort Variable Names

#+
#'## Semantic Sorting of Variable Names
#' This step ensures that all variable names documented in the Codebook are present in the data set and sorted according to the order in the Codebook. Where variables are missing in the data or undocumented variables are present this step will throw an error. 

#+
#'### Sort Variables: Full Data Set


setcolorder(data.best.en, # English
            c("doc_id",
              "text",
              "court",
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))


#'\newpage


setcolorder(data.best.fr, # French
            c("doc_id",
              "text",
              "court",
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))


#'\newpage
#+
#'### Sort Variables: Metadata

setcolorder(meta.best.en, # English
            c("doc_id",
              "court",
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))


#'\newpage


setcolorder(meta.best.fr, # French
            c("doc_id",
              "court",
              "caseno",
              "shortname",
              "fullname",
              "applicant",
              "respondent",
              "applicant_region",
              "respondent_region",
              "applicant_subregion",
              "respondent_subregion",
              "date",
              "doctype",
              "collision",
              "stage",
              "opinion",
              "language",
              "year",
              "minority",
              "nchars",            
              "ntokens",
              "ntypes",
              "nsentences",
              "version",
              "doi_concept",      
              "doi_version",
              "license"))






#'\newpage
#'## Number of Variables: Full Data Set

length(data.best.en) # English
length(data.best.fr) # French

#'## Number of Variables: Metadata

length(meta.best.en) # English
length(meta.best.fr) # French


#'## List All Variables: Full Data Set
#' "doc_id" is the filename, "text" is the extracted plaintext, third variable onwards are the metadata variables ("docvars").

names(data.best.en) # English
names(data.best.fr) # French


#'## List All Variables: Metadata

names(meta.best.en) # English
names(meta.best.fr) # French








#'# Calculate Detailed Token Frequencies


#+
#'## Create Corpora
corpus.en.b <- corpus(data.best.en)
corpus.fr.b <- corpus(data.best.fr)


#'## Process Tokens

quanteda_options(tokens_locale = "en") # Set Locale for Tokenization
tokens.en <- f.token.processor(corpus.en.b)

quanteda_options(tokens_locale = "fr") # Set Locale for Tokenization
tokens.fr <- f.token.processor(corpus.fr.b)


#'## Construct Document-Feature-Matrices
 
dfm.en <- dfm(tokens.en)
dfm.fr <- dfm(tokens.fr)

dfm.tfidf.en <- dfm_tfidf(dfm.en)
dfm.tfidf.fr <- dfm_tfidf(dfm.fr)




#'## Most Frequent Tokens | TF Weighting | Tables

#+
#'### English

tstat.en <- textstat_frequency(dfm.en,
                               n = 100)

fwrite(tstat.en, paste0(outputdir,
                        datashort,
                        "_EN_11_Top100Tokens_TF-Weighting.csv"))

kable(tstat.en,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Frequency",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")





#'### French

tstat.fr <- textstat_frequency(dfm.fr,
                               n = 100)

fwrite(tstat.fr, paste0(outputdir,
                        datashort,
                        "_FR_11_Top100Tokens_TF-Weighting.csv"))

kable(tstat.fr,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Frequency",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")




#'## Most Frequent Tokens | TFIDF Weighting | Tables

#+
#'### English

tstat.tfidf.en <- textstat_frequency(dfm.tfidf.en,
                                     n = 100,
                                     force = TRUE)

fwrite(tstat.en, paste0(outputdir,
                        datashort,
                        "_EN_12_Top100Tokens_TFIDF-Weighting.csv"))

kable(tstat.tfidf.en,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Weight",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")



#'### French

tstat.tfidf.fr <- textstat_frequency(dfm.tfidf.fr,
                                     n = 100,
                                     force = TRUE)

fwrite(tstat.fr, paste0(outputdir,
                        datashort,
                        "_FR_12_Top100Tokens_TFIDF-Weighting.csv"))

kable(tstat.tfidf.fr,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Feature",
                    "Weight",
                    "Rank",
                    "Docfreq",
                    "Group")) %>% kable_styling(latex_options = "repeat_header")





#'\newpage
#'## Most Frequent Tokens | TF Weighting | Scatterplots

#+
#'### English


#+ CD-ICJ_EN_13_Top50Tokens_TF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.en[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency))+
    geom_point()+
    coord_flip()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Top 50 Tokens | Term Frequency"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Frequency"
    )+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)




#'\newpage
#+
#'### French

#+ CD-ICJ_FR_13_Top50Tokens_TF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.fr[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency))+
    geom_point()+
    coord_flip()+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Top 50 Tokens | Term Frequency"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Frequency"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)




#'\newpage
#'## Most Frequent Tokens | TFIDF Weighting | Scatterplots

#+
#'### English

#+ CD-ICJ_EN_14_Top50Tokens_TFIDF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.tfidf.en[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency))+
    geom_point()+
    coord_flip()+
    theme_bw()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Top 50 Tokens | TF-IDF"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Weight"
    )+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)




#'\newpage
#+
#'### French

#+ CD-ICJ_FR_14_Top50Tokens_TFIDF-Weighting_Scatter, fig.height = 9, fig.width = 7
print(
    ggplot(data = tstat.tfidf.fr[1:50, ],
           aes(x = reorder(feature,
                           frequency),
               y = frequency)) +
    geom_point() +
    coord_flip() +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Top 50 Tokens | TF-IDF"),
        caption = paste("DOI:",
                        doi.version),
        x = "Feature",
        y = "Weight"
    )+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 12,
                                  face = "bold")
    )
)





#'\newpage
#'## Most Frequent Tokens | TF Weighting | Wordclouds

#+
#'### English

#+ CD-ICJ_EN_15_Top100Tokens_TF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.en,
                   max_words = 100,
                   min_size = 1,
                   max_size = 5,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))

#'\newpage
#+
#'### French


#+ CD-ICJ_FR_15_Top100Tokens_TF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.fr,
                   max_words = 100,
                   min_size = 1,
                   max_size = 5,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))


#'\newpage
#'## Most Frequent Tokens | TFIDF Weighting | Wordclouds


#+
#'### English

#+ CD-ICJ_EN_16_Top100Tokens_TFIDF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.tfidf.en,
                   max_words = 100,
                   min_size = 1,
                   max_size = 2,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))

#'\newpage
#+
#'### French


#+ CD-ICJ_FR_16_Top100Tokens_TFIDF-Weighting_Cloud, fig.height = 7, fig.width = 7
textplot_wordcloud(dfm.tfidf.fr,
                   max_words = 100,
                   min_size = 1,
                   max_size = 2,
                   random_order = FALSE,
                   rotation = 0,
                   color = brewer.pal(8, "Dark2"))








#'# Document Similarity
#' This analysis computes the correlation similarity for all documents in each corpus, plots the number of documents to drop as a function of the correlation similarity threshold and outputs the document IDs for specific threshold values.
#'
#' The similarity test uses the standard pre-processed unigram document-feature matrix created by the f.token.processor function for the analyses of detailed token frequencies, i.e. it includes removal of numbers, special characters, stopwords (English/French) and lowercasing. I investigated other pre-processing workflows without the removal of features or lowercasing, as well as bigrams and trigrams, but, based on a qualitative assessment of the results, these performed no better or even worse than the standard workflow. Further research will be required to provide a definitive recommendation on how to deduplicate the corpus.
#'
#' I intentionally do not correct for length, as the analysis focuses on detecting duplicates and near-duplicates, not topical similarity.


#+
#'## Set Ranges
#'
#' **Note:** These ranges should cover most use cases.

threshold.range <- seq(0.8, 1, 0.005)

threshold.N <- length(threshold.range)

print(threshold.range)


print.range <- seq(0.8, 0.99, 0.01)

print(print.range)

#'\newpage
#+
#'## English


#+
#'### Calculate Similarity

sim <- textstat_simil(dfm.en,
                      margin = "documents",
                      method = "correlation")

sim.dt <- as.data.table(sim)



#'### Create Empty Lists

list.ndrop <- vector("list",
                    threshold.N)

list.drop.ids <- vector("list",
                        threshold.N)

list.pair.ids <- vector("list",
                        threshold.N)


#'### Build Tables

for (i in 1:threshold.N){
    
    threshold <- threshold.range[i]

    pair.ids <- sim.dt[correlation > threshold]
    
    list.pair.ids[[i]] <- pair.ids
    
    drop.ids <- sim.dt[correlation > threshold,
                       .(unique(document1))][order(V1)]
    
    list.drop.ids[[i]] <- drop.ids
    
    ndrop <- drop.ids[,.N]
    
    list.ndrop[[i]] <- data.table(threshold,
                                  ndrop)
}


dt.ndrop <- rbindlist(list.ndrop)


#'### IDs of Paired Documents Above Threshold
#' IDs of document pairs, with one of them to drop, as function of correlation similarity.

for (i in print.range){
   
    index <- match(i, threshold.range)
    
    fwrite(list.pair.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_EN_17_DocumentSimilarity_Correlation_PairedDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))
}



#'### IDs of Duplicate Documents per Threshold
#' IDs of Documents to drop as function of correlation similarity.

for (i in print.range){

    index <- match(i, threshold.range)
    
    fwrite(list.drop.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_EN_17_DocumentSimilarity_Correlation_DuplicateDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))
}



#'### Count of Duplicate Documents per Threshold
#' Number of Documents to drop as function of correlation similarity.

kable(dt.ndrop,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Threshold",
                    "Number to Drop")) %>% kable_styling(latex_options = "repeat_header")

fwrite(dt.ndrop,
       paste0(outputdir,
              datashort,
              "_EN_18_DocumentSimilarity_Correlation_Table.csv"))




#'\newpage
#+ CD-ICJ_EN_19_DocumentSimilarity_Correlation, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.ndrop,
           aes(x = threshold,
               y = ndrop))+
    geom_line()+
    geom_point()+
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Document Similarity (Correlation)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Correlation Similarity Threshold",
        y = "Number of Documents Above Threshold"
    )+
    scale_x_continuous(breaks = seq(0.8, 1, 0.02))+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "bottom",
        legend.direction = "vertical"
    )
)







#'\newpage
#'## French


#'### Calculate Similarity

sim <- textstat_simil(dfm.fr,
                      margin = "documents",
                      method = "correlation")

sim.dt <- as.data.table(sim)



#'### Create Empty Lists

list.ndrop <- vector("list",
                     threshold.N)

list.drop.ids <- vector("list",
                        threshold.N)

list.pair.ids <- vector("list",
                        threshold.N)


#'### Build Tables

for (i in 1:threshold.N){
    
    threshold <- threshold.range[i]

    pair.ids <- sim.dt[correlation > threshold]
    
    list.pair.ids[[i]] <- pair.ids
    
    drop.ids <- sim.dt[correlation > threshold,
                       .(unique(document1))][order(V1)]
    
    list.drop.ids[[i]] <- drop.ids
    
    ndrop <- drop.ids[,.N]
    
    list.ndrop[[i]] <- data.table(threshold,
                                  ndrop)
}

dt.ndrop <- rbindlist(list.ndrop)



#'### IDs of Paired Documents Above Threshold
#' IDs of document pairs, with one of them to drop, as function of correlation similarity.

for (i in print.range){
   
    index <- match(i, threshold.range)
    
    fwrite(list.pair.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_FR_17_DocumentSimilarity_Correlation_PairedDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))
}


#'### IDs of Duplicate Documents per Threshold
#' IDs of Documents to drop as function of correlation similarity.

for (i in print.range){

    index <- match(i, threshold.range)
    
    fwrite(list.drop.ids[[index]],
           paste0(outputdir,
                  datashort,
                  "_FR_17_DocumentSimilarity_Correlation_DuplicateDocIDs_",
                  str_pad(threshold.range[index],
                          width = 5,
                          side = "right",
                          pad = "0"),
                  ".csv"))

}



#'### Count of Duplicate Documents per Threshold
#' Number of Documents to drop as function of correlation similarity.

kable(dt.ndrop,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Threshold",
                    "Number to Drop")) %>% kable_styling(latex_options = "repeat_header")

fwrite(dt.ndrop,
       paste0(outputdir,
              datashort,
              "_FR_18_DocumentSimilarity_Correlation_Table.csv"))



#'\newpage
#+ CD-ICJ_FR_19_DocumentSimilarity_Correlation, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.ndrop,
           aes(x = threshold,
               y = ndrop))+
    geom_line()+
    geom_point()+
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Document Similarity (Correlation)"),
        caption = paste("DOI:",
                        doi.version),
        x = "Correlation Similarity Threshold",
        y = "Number of Documents Above Threshold"
    )+
    scale_x_continuous(breaks = seq(0.8, 1, 0.02))+
    theme_bw()+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position="bottom",
        legend.direction = "vertical"
    )
)









#+
#'# Create CSV Files

#+
#'## Full Data Set

csvname.full.en <- paste(datashort,
                         datestamp,
                         "EN_CSV_BEST_FULL.csv",
                         sep = "_")

csvname.full.fr <- paste(datashort,
                         datestamp,
                         "FR_CSV_BEST_FULL.csv",
                         sep = "_")


fwrite(data.best.en,
       csvname.full.en,
       na = "NA")

fwrite(data.best.fr,
       csvname.full.fr,
       na = "NA")



#'## Metadata Only
#' These files are the same as the full data set, minus the "text" variable.

csvname.meta.en <- paste(datashort,
                    datestamp,
                    "EN_CSV_BEST_META.csv",
                    sep = "_")

csvname.meta.fr <- paste(datashort,
                    datestamp,
                    "FR_CSV_BEST_META.csv",
                    sep = "_")


fwrite(meta.best.en,
       csvname.meta.en,
       na = "NA")

fwrite(meta.best.fr,
       csvname.meta.fr,
       na = "NA")





#'# Final File Count per Folder

dir.table <- as.data.table(dirset)[, {
    filecount <- lapply(dirset,
                        function(x){length(list.files(x))})
    list(dirset, filecount)
}]


kable(dir.table,
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE,
      linesep = "",
      col.names = c("Directory",
                    "Filecount"))



#'# File Size Distribution

#'## English

#'### Corpus Object in RAM

print(object.size(data.best.en),
      humanReadable = TRUE,
      units = "MB")


#'### Create Data Table of Filenames

best <- list.files("EN_PDF_BEST_FULL",
                   full.names = TRUE)

original <- list.files("EN_PDF_ORIGINAL_FULL",
                       full.names = TRUE)

MB <- file.size(best) / 10^6

dt1 <- data.table(MB,
                  rep("BEST",
                      length(MB)))


MB <- file.size(original) / 10^6

dt2 <- data.table(MB, rep("ORIGINAL",
                          length(MB)))


dt <- rbind(dt1,
            dt2)

setnames(dt,
         "V2",
         "variant")


#'### Total Size Comparison

kable(dt[,
         .(MB_total = sum(MB)),
         keyby = variant],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)




#'### Analyze Files Larger than 10 MB

# Summarize
summary(dt[MB > 10]$MB)



# Space required by large files

kable(dt[MB > 10,
         .(total = sum(MB)),
         keyby = variant],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)


# Show Individual Large File Sizes

kable(dt[MB > 10][order(MB)],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)


#'\newpage
#'### Plot Density Distribution for Files 10MB or Less
dt.plot <- dt[MB <= 10]


#+ CD-ICJ_EN_20_FileSizesDensity_Less10MB, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.plot,
           aes(x = MB,
               group = variant,
               fill = variant))+
    geom_density()+
    theme_bw()+
    facet_wrap(~variant,
               ncol = 2) +
    labs(
        title = paste(datashort,
                      "| EN | Version",
                      datestamp,
                      "| Distribution of File Sizes up to 10 MB"),
        caption = paste("DOI:",
                        doi.version),
        x = "File Size in MB",
        y = "Density"
    )+
    scale_fill_viridis(end = 0.35, discrete = TRUE) +
    scale_color_viridis(end = 0.35, discrete = TRUE) +
    scale_x_continuous(breaks = seq(0, 10, 2))+
    theme(
        text = element_text(size=  14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        panel.spacing = unit(0.1,
                             "lines"),
        axis.ticks.x = element_blank()
    )
)

#'\newpage
#'## French

#'### Corpus Object in RAM

print(object.size(data.best.en),
      humanReadable = TRUE,
      units = "MB")


#'### Create Data Table of filenames

best <- list.files("FR_PDF_BEST_FULL",
                   full.names = TRUE)

original <- list.files("FR_PDF_ORIGINAL_FULL",
                       full.names = TRUE)


MB <- file.size(best) / 10^6

dt1 <- data.table(MB,
                  rep("BEST",
                      length(MB)))



MB <- file.size(original) / 10^6

dt2 <- data.table(MB,
                  rep("ORIGINAL",
                      length(MB)))

dt <- rbind(dt1,
            dt2)

setnames(dt,
         "V2",
         "variant")



#'### Total Size Comparison

kable(dt[,
         .(MB_total = sum(MB)),
         keyby = variant],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)


#'### Analyze Files Larger than 10 MB

summary(dt[MB > 10]$MB)



# Space required by large files

kable(dt[MB > 10,
         .(total = sum(MB)),
         keyby = variant],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)


# Show Individual Large File Sizes

kable(dt[MB > 10][order(MB)],
      format = "latex",
      align = "r",
      booktabs = TRUE,
      longtable = TRUE)




#'\newpage
#'### Plot Density Distribution for Files 10MB or Less

dt.plot <- dt[MB <= 10]

#+ CD-ICJ_FR_20_FileSizesDensity_Less10MB, fig.height = 6, fig.width = 9
print(
    ggplot(data = dt.plot,
           aes(x = MB,
               group = variant,
               fill = variant)) +
    geom_density() +
    theme_bw() +
    facet_wrap(~variant,
               ncol=2) +
    labs(
        title = paste(datashort,
                      "| FR | Version",
                      datestamp,
                      "| Distribution of File Sizes up to 10 MB"),
        caption = paste("DOI:",
                        doi.version),
        x = "File Size in MB",
        y = "Density"
    )+
    scale_fill_viridis(end = 0.35, discrete = TRUE) +
    scale_color_viridis(end = 0.35, discrete = TRUE) +
    scale_x_continuous(breaks = seq(0, 10, 2))+
    theme(
        text = element_text(size = 14),
        plot.title = element_text(size = 14,
                                  face = "bold"),
        legend.position = "none",
        panel.spacing = unit(0.1,
                             "lines"),
        axis.ticks.x = element_blank()
    )
)




#'# Create ZIP Archives

#+
#'## ZIP CSV Files

csv.zip.name.full.en <- gsub(".csv",
                             "",
                             csvname.full.en)

csv.zip.name.full.fr <- gsub(".csv",
                             "",
                             csvname.full.fr)

csv.zip.name.meta.en <- gsub(".csv",
                             "",
                             csvname.meta.en)

csv.zip.name.meta.fr <- gsub(".csv",
                             "",
                             csvname.meta.fr)


#+ results = 'hide'
zip(csv.zip.name.full.fr,
    csvname.full.fr)

zip(csv.zip.name.full.en,
    csvname.full.en)

zip(csv.zip.name.meta.fr,
    csvname.meta.fr)

zip(csv.zip.name.meta.en,
    csvname.meta.en)


#'## ZIP Data Directories

#' **Note:** Vector of Directories was created at the beginning of the script.

for (dir in dirset){
    zip(paste(datashort,
              datestamp,
              dir,
              sep = "_"),
        dir)
}


#'\newpage
#'## ZIP ANALYSIS Directory

zip(paste(datashort,
          datestamp,
          "EN-FR",
          basename(outputdir),
          sep = "_"),
    basename(outputdir))



#'## ZIP Unlabelled Files Directory

zip(dir.unlabelled,
    dir.unlabelled)


#'## ZIP Source Files

files.source <-  c(system2("git", "ls-files", stdout = TRUE),
                       ".git")

 

zip(paste(datashort,
          datestamp,
          "Source_Files.zip",
          sep = "_"),
    files.source)




#'# Delete CSV and Directories
#' The metadata CSV files are retained for Codebook generation.

#+
#'## Delete CSVs

unlink(csvname.full.fr)
unlink(csvname.full.en)
unlink(csvname.meta.fr)
unlink(csvname.meta.en)



#'## Delete Data Directories
for (dir in dirset){
    unlink(dir,
           recursive = TRUE)
}

unlink(dir.unlabelled,
       recursive = TRUE)



#'# Cryptography Module
#' This module computes two types of hashes for every ZIP archive: SHA2-256 and SHA3-512. These are proof of the authenticity and integrity of data and document that the files are the result of this source code. The SHA-2 and SHA-3 family of algorithms are highly resistant to collision and pre-imaging attacks in reasonable scenarios and can therefore be considered secure according to current public cryptographic research. SHA3 hashes with an output length of 512 bit may even provide sufficient security when attacked with quantum cryptanalysis based on Grover's algorithm.

#+
#'## Create Set of ZIP Archives
files.zip <- list.files(pattern = "\\.zip$",
                        ignore.case = TRUE)
                       


#'## Show Function: f.dopar.multihashes
#+ results = "asis"
print(f.dopar.multihashes)


#'## Compute Hashes
multihashes <- f.dopar.multihashes(files.zip)


#'## Convert to Data Table
setDT(multihashes)



#'## Add Index
multihashes$index <- seq_len(multihashes[,.N])

#'\newpage
#'## Save to Disk
fwrite(multihashes,
       paste(datashort,
             datestamp,
             "CryptographicHashes.csv",
             sep = "_"),
       na = "NA")


#'## Add Whitespace to Enable Automatic Linebreak
#' This is only used for display and will be discarded after printing to the Compilation Report.

multihashes$sha3.512 <- paste(substr(multihashes$sha3.512, 1, 64),
                              substr(multihashes$sha3.512, 65, 128))


#'\newpage
#'## Print to Report

kable(multihashes[,.(index,filename)],
      format = "latex",
      align = c("p{1cm}",
                "p{13cm}"),
      booktabs = TRUE,
      longtable = TRUE) 


#'\newpage
kable(multihashes[,.(index,sha2.256)],
      format = "latex",
      align = c("c",
                "p{13cm}"),
      booktabs = TRUE,
      longtable = TRUE)


#'\newpage
kable(multihashes[,.(index,sha3.512)],
      format = "latex",
      align = c("c",
                "p{13cm}"),
      booktabs = TRUE,
      longtable = TRUE)






#'# Finalize


#+
#'## Datestamp
print(datestamp)


#'## Date and Time (Begin)
print(begin.script)


#'## Date and Time (End)
end.script <- Sys.time()
print(end.script)


#'## Script Runtime
print(end.script - begin.script)


#'## Warnings
warnings()



#'# Strict Replication Parameters
sessionInfo()

system2("openssl",
        "version",
        stdout = TRUE)

system2("tesseract",
        "-v",
        stdout = TRUE)

system2("convert",
        "--version",
        stdout = TRUE)


print(quanteda_options())



#+
#'# References
