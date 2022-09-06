#'---
#'title: "Codebook | Corpus of Decisions: International Court of Justice (CD-ICJ)"
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
#'      before_body: [tex/CD-ICJ_Source_TEX_Author.tex,temp/CD-ICJ_Source_TEX_Definitions.tex,tex/CD-ICJ_Source_TEX_CodebookTitle.tex]
#'bibliography: temp/packages.bib
#'nocite: '@*'
#' ---

#'\newpage

#+ echo = FALSE 
knitr::opts_chunk$set(fig.pos = "center",
                      echo = FALSE,
                      warning = FALSE,
                      message = FALSE)




############################
### Packages
############################

#+
library(knitr)         # Scientific Reporting
library(kableExtra)    # Enhanced Knitr Tables
library(magick)        # Required for cropping when compiling PDF
library(parallel)      # Base R Parallelization
library(data.table)    # Advanced Data Handling

setDTthreads(threads = detectCores()) 


############################
### Preamble
############################

datashort <- "CD-ICJ"



files.zip <- list.files(pattern = "\\.zip")

datestamp <- unique(tstrsplit(files.zip,
                              split = "_")[[2]])



prefix.en <- paste0("ANALYSIS/",
                    datashort,
                    "_EN_01_FrequencyTable_var-")

prefix.fr <- paste0("ANALYSIS/",
                    datashort,
                    "_FR_01_FrequencyTable_var-")


############################
### Read Tables: Frequency
############################

table.doctype.en <- fread(paste0(prefix.en, "doctype.csv"))[,-3]
table.doctype.fr <- fread(paste0(prefix.fr, "doctype.csv"))[,-3]

table.opinion.en <- fread(paste0(prefix.en, "opinion.csv"))[,-3]
table.opinion.fr <- fread(paste0(prefix.fr, "opinion.csv"))[,-3]

table.year.en <- fread(paste0(prefix.en, "year.csv"))[,-3]
table.year.fr <- fread(paste0(prefix.fr, "year.csv"))[,-3]

table.applicant.en <- fread(paste0(prefix.en, "applicant.csv"))[,-3]
table.applicant.fr <- fread(paste0(prefix.fr, "applicant.csv"))[,-3]

table.respondent.en <- fread(paste0(prefix.en, "respondent.csv"))[,-3]
table.respondent.fr <- fread(paste0(prefix.fr, "respondent.csv"))[,-3]


##############################
### Read Tables: Entity Codes
##############################

table.countrycodes <- fread("data/CD-ICJ_Source_CountryCodes.csv")
table.advcodes <- fread("data/CD-ICJ_Source_AdvisoryRequestCoding.csv")

############################
### Read Tables: Linguistic
############################

stats.ling.en <-  fread("ANALYSIS/CD-ICJ_EN_00_CorpusStatistics_Summaries_Linguistic.csv")
stats.ling.fr <-  fread("ANALYSIS/CD-ICJ_FR_00_CorpusStatistics_Summaries_Linguistic.csv")


############################
### Read Metadata
############################

meta.zip.en <- paste(datashort,
                     datestamp,
                     "EN_CSV_BEST_META.zip",
                     sep = "_")

meta.best.en <- fread(cmd = paste("unzip -cq",
                                  meta.zip.en))


############################
### Read Hash File
############################

hashfile <- paste(datashort,
                  datestamp,
                  "CryptographicHashes.csv",
                  sep = "_")


############################
### Begin Text
############################


#'# Introduction

#'The \textbf{\icj\ (ICJ)} is the primary judicial organ of the United Nations and one of the most consequential courts in international law.
#'
#' Called the \enquote{World Court} by many, it is the only international court with general thematic jurisdiction. While critics occasionally note the lack of compulsory jurisdiction and sharply limited access to the Court,\footnote{Only States may be  party to proceedings in contentious jurisdiction and only certain bodies of international organizations may request advisory opinions.} its opinions continue to have an outsize influence on the modern interpretation, codification and wider development of international law. Every international legal textbook covers the workings and decisions of the Court *in extenso* and participation in international moot courts, such as the Philip C. Jessup Moot Court, without regular reference to and citation of the \icj 's decisions, is unthinkable. 
#' 
#'The \textbf{\datatitle\ (\datashort)} collects and presents for the first time in human- and machine-readable form all published decisions of the \icj . Among these are judgments, advisory opinions and orders, as well as their respective appended minority opinions (declarations, separate opinions and dissenting opinions).
#'
#' 
#' This data set is designed to be complementary to and fully compatible with the \emph{Corpus of Decisions: Permanent Court of International Justice (CD-PCIJ)}, which is also available open access.\footnote{Corpus of Decisions: Permanent Court of International Justice (CD-PCIJ). <\url{https://doi.org/10.5281/zenodo.3840480}>.}
#'
#' 
#' The quantitative analysis of international legal data is still in its infancy, a situation which is exacerbated by the lack of high-quality empirical data. Most advanced data sets are held in commercial databases and are therefore not easily available to academic researchers, journalists and the general public. With this data set I hope to contribute to a more systematic and empirical view of the international legal system. In an international community founded on the rule of law the activities of the judiciary must be public, transparent and defensible. In the 21st century this requires quantitative scientific review of decisions and actions. 
#'
#' Design, construction and compilation of this data set are based on the principles of general availability through freedom from copyright (public domain status), strict transparency and full scientific reproducibility. The *FAIR Guiding Principles for Scientific Data Management and Stewardship* (Findable, Accessible, Interoperable and Reusable) inspire both the design and the manner of publication.\footnote{Wilkinson, M., Dumontier, M., Aalbersberg, I. et al. The FAIR Guiding Principles for Scientific Data Management and Stewardship. Sci Data 3, 160018 (2016). <\url{https://doi.org/10.1038/sdata.2016.18}>.}







#+
#'# Reading Files

#' The data are published in open, interoperable and widely used formats (CSV, TXT, PDF). They can be used with all modern programming languages (e.g. Python or R) and graphical interfaces. The PDF collections are intended to facilitate traditional legal research.
#'
#' **Important:** Missing values are always coded as \enquote{NA}.

#+
#'## CSV Files
#'
#' Working with the CSV files is recommended. CSV\footnote{The CSV format is defined in RFC 4180: <\url{https://tools.ietf.org/html/rfc4180}>.} is an open and simple machine-readable tabular data format. In this data set values are separated by commas. Each column is a variable and each row is a document. Variables are explained in detail in section \ref{variables}.

#'
#' To read \textbf{CSV} files into R I strongly recommend using the fast file reader **fread()** from the **data.table** package (available on CRAN). The file can be read into \textbf{R} like so: 

#+ eval = FALSE, echo = TRUE
library(data.table)
icj.en <- fread("filename.csv")


#'## TXT Files
#'The \textbf{TXT} files, including metadata, can be read into \textbf{R} with the package \textbf{readtext} (available on CRAN) thus:

#+ eval = FALSE, echo = TRUE
library(readtext)
icj.en <- readtext("EN_TXT_BEST_FULL/*.txt",
                   docvarsfrom = "filenames", 
                   docvarnames = c("court",
                                   "caseno",
                                   "shortname",
                                   "applicant",
                                   "respondent",
                                   "date",
                                   "doctype",
                                   "collision",
                                   "opinion",
                                   "language"),
                   dvsep = "_", 
                   encoding = "UTF-8")




#+
#'# Data Set Design


#'## Description of Data Set

#'The \textbf{\datatitle\ (\datashort)} collects and structures in human- and machine-readable form all published decisions of the \icj . Among these are judgments, advisory opinions and orders, as well as their respective appended minority opinions (declarations, separate opinions and dissenting opinions).
#'

#' It consists of a CSV file of the full data set, a CSV file with the metadata only, individual TXT files for each document and PDF files with an enhanced text layer generated by the LSTM neural network engine of the optical character recognition software (OCR) \emph{Tesseract}.
#'
#' Additionally, the raw PDF files and some intermediate stages of refinement are included to allow for easier replication of results and for production use in the event that even higher quality methods of optical character recognition (OCR) can be applied to the documents in the future.


#+
#'## Complementarity

#' This data set is intended to be complementary to and fully compatible with the \emph{Corpus of Decisions: Permanent Court of International Justice (CD-PCIJ)}, which is also available open access.\footnote{Corpus of Decisions: Permanent Court of International Justice (CD-PCIJ). <\url{https://doi.org/10.5281/zenodo.3840480}>.}
#' 

#+
#'## Table of Sources


#'\begin{centering}
#'\begin{longtable}{P{5cm}p{9cm}}

#'\toprule
#' Data Source & Citation \\

#'\midrule

#' Primary Data Source & \url{https://www.icj-cij.org}\\
#' Source Code & \url{\softwareversionurldoi}\\
#' Country Codes & \url{\softwareversionurldoi}\\
#' Entity Codes & \url{\softwareversionurldoi}\\
#' Cases Names and Parties  & \url{\softwareversionurldoi}\\

#'\bottomrule

#'\end{longtable}
#'\end{centering}






#+
#'## Data Collection
#' Data were collected with the explicit consent of the Registry of the \icj . All documents were downloaded via TLS-encrypted connections and cryptographically signed after data processing was complete. The data set collects all decisions and appended opinions issued by the \icj\ that were published on the official website of the \icj\ on \version .

 
#+
#'## Source Code and Compilation Report
#'
#' The full Source Code for the creation of this data set, the resulting Compilation Report and this Codebook are published open access and permanently archived in the scientific repository of CERN.
#'
#' With every compilation of the full data set an extensive **Compilation Report** is created in a professionally layouted PDF format (comparable to this Codebook). The Compilation Report includes the Source Code, comments and explanations of design decisions, relevant computational results, exact timestamps and a table of contents with clickable internal hyperlinks to each section. The Compilation Report is published under the same DOI as the Source Code.
#'
#' For details of the construction and validation of the data set please refer to the Compilation Report.


#+
#'## Limitations
#'Users should bear in mind certain limitations:

#'\begin{enumerate}
#' \item The data set contains only those documents which were published by the ICJ and have been made available by the ICJ on its official website (\emph{publication bias}).
#' \item While Tesseract yields high-quality OCR results, current OCR technology is not perfect and minor errors must be expected (\emph{OCR bias}).
#' \item Automatic language detection is not foolproof and some bilingual documents marked as monolingual may have gone undetected (\emph{language mismatch}).
#' \item Lengthy quotations in languages other than the language indicated in the metadata may further confound analyses (\emph{language blurring}).
#'\end{enumerate}



#+
#'## Public Domain Status
#' 
#'According to written communication between the author and the Registry of the \icj\ the original documents are not subject to copyright.
#'
#' To ensure the widest possible distribution and to promote the international rule of law I waive any copyright to the data set under a \textbf{Creative Commons CC0 1.0 Universal (CC0 1.0) Public Domain Dedication}. For details of the license please refer to the CC0 copyright notice at the beginning of this Codebook or visit the Creative Commons website for the full terms of the license.\footnote{\url{https://creativecommons.org/publicdomain/zero/1.0/legalcode}}


#'\newpage
#+
#'## Quality Assurance

#' Dozens of automated tests were conducted to ensure the quality of the data and metadata, for example:
#'
#' \begin{enumerate}
#'\item Auto-detection of language via analysis of n-gram patterns with the \emph{textcat} package for R.
#'\item Strict validation of variable types via \emph{regular expressions}.
#'\item Construction of frequency tables for (almost) every variable followed by human review to detect anomalies.
#'\item Creation of visualizations for many common descriptive analyses.
#'\end{enumerate}
#'
#'For results of each test and more information on the construction of the data set please refer to the Compilation Report or the \enquote{ANALYSIS} archive included with the data set.







#' \begin{sidewaysfigure}
#'\includegraphics{ANALYSIS/CD-ICJ_Workflow_1.pdf}
#' \caption{Workflow Schematic Part 1: Download, Labelling, Conversion and Sorting of Documents}
#' \end{sidewaysfigure}




#' \begin{sidewaysfigure}
#'\includegraphics{ANALYSIS/CD-ICJ_Workflow_2.pdf}
#'  \caption{Workflow Schematic Part 2: Ingestion, Pre-Processing, Analysis and Creation of CSV Files}
#' \end{sidewaysfigure}





#+
#'# Variants and Primary Target Audiences

#'The data set is provided in two language versions (English and French), as well as several differently processed variants geared towards specific target audiences.
#'
#' A reduced PDF variant of the data set containing only majority opinions is intended to assist practitioners.
#'
#' \medskip

#'\begin{centering}
#'\begin{longtable}{p{4cm}p{10cm}}

#'\toprule

#'Variant & Target Audience and Description \\

#'\midrule
#'\endhead

#'PDF\_BEST & \textbf{Traditional Legal Research (recommended).} A synthesis of all born-digital documents issued by the ICJ combined with older scanned documents (prior to 2005) which were given a new and enhanced text layer created with an advanced LSTM neural network machine learning engine. Its main advantages are vastly improved local searches in individual documents via Ctrl+F and copy/pasting without the need for extensive manual revisions. Researchers with slow internet connections should consider using the \enquote{TXT\_BEST} variant, as this still provides a reasonable visual approximation of the original documents, but offers the advantage of drastically reduced file size.  A reduced PDF variant of the data set containing only majority opinions is available to assist practitioners.\\
#'CSV\_BEST & \textbf{Quantitative Research (recommended).} A structured representation of the full data set within a single comma-delimited file. Includes the full complement of metadata described in the Codebook. The \enquote{FULL} sub-variant includes the full text of the decisions, whereas the sub-variant \enquote{META} only contains the metadata.\\
#'TXT\_BEST & \textbf{Quantitative Research.} A synthesis of TXT files created by combining the extracted text of all born-digital documents issued by the ICJ (2005 and later) and the  OCR texts from older scanned documents (prior to 2005) generated with an advanced LSTM neural network machine learning engine. R users should strongly consider using the package \emph{readtext} to read them into R with the filename metadata intact.\\
#'ANALYSIS & \textbf{Quantitative Research.} This archive contains almost all of the machine-readable analysis output generated during the data set creation process to facilitate further analysis (CSV for tables, PDF and PNG for plots). Minor analysis results are documented only in the Compilation Report.\\
#'TXT\_EXTRACTED & \textbf{Replication Research and Creation of New Data Sets.} TXT files containing the extracted text layer from all original documents as published by the ICJ. The quality of the original OCR text for older documents is poor and this variant should not be used for statistical analysis. Documents dated 2005 or later were born-digital and can be used for all purposes.\\
#'TXT\_TESSERACT & \textbf{Replication Research and Creation of New Data Sets.} TXT files containing the OCR text generated with an advanced LSTM neural network machine learning engine for documents predating 2005.  Fully included in the BEST variant, but provided separately for reasons of transparency.\\
#'PDF\_ORIGINAL & \textbf{Replication Research and Creation of New Data Sets.} The original documents with the original text layer. Only recommended for researchers who wish to replicate the machine-readable files or who wish to create a new and improved data set. Not recommended for traditional research, as the quality of the original OCR text layer is quite poor.\\
#'PDF\_ENHANCED & \textbf{Replication Research and Creation of New Data Sets.} Scanned documents of opinions rendered before 2005 which were given a new and enhanced text layer generated with an advanced LSTM neural network machine learning engine. Fully included in the BEST variant, but provided separately for reasons of transparency.\\


#'\bottomrule

#'\end{longtable}
#'\end{centering}



#+
#'\newpage



#+
#'# Variables



#+
#'## General Remarks

#' \begin{itemize}
#'
#' \item Missing values are always coded as \enquote{NA}.
#'
#' \item All Strings are encoded in UTF-8.
#' 
#' \item A significant part of the metadata was included with the files downloaded from the Court's website.
#'
#' \item The variables \enquote{shortname}, \enquote{applicant}, \enquote{respondent},  \enquote{stage}, \enquote{applicant\_region}, \enquote{applicant\_subregion}, \enquote{respondent\_region} and \enquote{respondent\_subregion} were coded manually by the author of the data set and added automatically at compilation time. Country codes conform to the ISO 3166 Alpha-3 standard and geographical classifications to the M49 standard used by the UN Statistics Division. 
#'
#' \item The variable \enquote{fullname} is coded according to case headings as published on the ICJ website. Includes the full names of the parties in parentheses. Introductory phrases such as \enquote{Case concerning...} are omitted.
#'
#' \item The variables \enquote{nchars}, \enquote{ntokens}, \enquote{ntypes}, \enquote{nsentences} and \enquote{year} were calculated automatically based on the content and metadata of each document.
#'
#' \item The variables \enquote{version}, \enquote{doi\_concept}, \enquote{doi\_version} and \enquote{license} were added automatically during the data set creation process to document provenance and to comply with FAIR Data Principles F1, F3 and R1.1.
#'
#' \end{itemize}


#'\vspace{1cm}

#+
#'## Structure of TXT File Names

#'\begin{verbatim}
#'[court]_[caseno]_[shortname]_[applicant]_[respondent]_[date]_[doctype]_
#'[collision]_[stage]_[opinion]_[language]
#'\end{verbatim}

#'\vspace{1cm}

#'\subsection{Example TXT File Name}

#'\begin{verbatim}
#' ICJ_001_CorfuChannel_GBR_ALB_1949-04-09_JUD_01_ME_05_EN.txt
#'\end{verbatim}


#'\newpage
#+
#'## Structure of CSV Metadata

str(meta.best.en)

#'\newpage
#+
#'## Detailed Description of Variables


#'\begin{centering}
#'\begin{longtable}{p{3.5cm}p{2cm}p{9cm}}



#'\toprule

#'Variable & Type & Details\\

#'\midrule

#'\endhead

#' doc\_id & String & (CSV only) The name of the imported TXT file.\\
#' text & String & (CSV only) The full content of the imported TXT file.\\
#' court & String & The variable only takes the value \enquote{ICJ}, which stands for \enquote{\icj}. It is generally only useful if combined with the CD-PCIJ or other data sets.\\
#' caseno & Integer & The case number assigned by the ICJ. The same case may span multiple case numbers, i.e. the Interpretation or Revision stages have different case numbers than the original judgment. To analyze all stages of a case I  recommend a pattern search on the variable \enquote{shortname}. Note: case number 2 is unassigned and there are no documents for case number 2 available on the ICJ website.\\
#' shortname & String & Short name of the case. This was custom-created by the author based on the original title. Short names include well-known components (e.g. \enquote{Nicaragua}) to facilitate quick local searches and try to be as faithful to the full title as possible. For requests concerning interpretation or revision of a judgment the shortname is followed by \enquote{Interpretation} or \enquote{Revision}.\\
#' fullname & String & (CSV only) Full name of the case as published on the ICJ website. Includes the full names of the Parties. Introductory phrases such as \enquote{Case concerning...} are omitted.\\
#' applicant & String & The unique identifier of the applicant. In contentious proceedings this is the three-letter (Alpha-3) country code as per the ISO 3166-1 standard. Table \ref{tab:countrycodes} contains an explanation of all country codes used in the data set. Please note that reserved country codes are in use for historical entities (e.g. the Soviet Union). For advisory proceedings this variable refers to the entity which requested an advisory opinion. Table \ref{tab:entities} explains the detailed advisory coding decisions.\\
#' respondent & String & The unique identifier of the respondent. In contentious proceedings this is the three-letter (Alpha-3) country code as per the ISO 3166-1 standard. Table \ref{tab:countrycodes} contains an explanation of all country codes used in the data set. Please note that reserved country codes are in use for historical entities (e.g. the Soviet Union). Advisory proceedings do not have a respondent and therefore always take the value \enquote{NA}.\\
#' applicant\_region & String & (CSV only) The geographical region of the applicant according to the UN M49 standard. Please refer to table \ref{tab:countrycodes} for details and exceptions. Geographical information is only available for countries, not for UN bodies or international organizations.\\
#' respondent\_region & String & (CSV only) The geographical region of the respondent according to the UN M49 standard. Please refer to table \ref{tab:countrycodes} for details and exceptions. Geographical information is only available for countries, not for UN bodies or international organizations.\\
#' applicant\_subregion & String & (CSV only) The geographical subregion of the applicant according to the UN M49 standard. Please refer to table \ref{tab:countrycodes} for details and exceptions. Geographical information is only available for countries, not for UN bodies or international organizations.\\
#' respondent\_subregion & String & (CSV only) The geographical subregion of the respondent according to the UN M49 standard. Please refer to table \ref{tab:countrycodes} for details and exceptions. Geographical information is only available for countries, not for UN bodies or international organizations.\\
#' date & ISO Date & The date of the document in the format YYYY-MM-DD (ISO-8601).\\
#' doctype & String & A three-letter code indicating the type of document. Possible values are \enquote{JUD} (judgments in contentious jurisdiction), \enquote{ADV} (advisory opinions) and \enquote{ORD} (orders in all types of jurisidiction).\\
#' collision & Integer & In rare instances the \icj\ issued several decisions of the same type in the same proceedings on the same day. Most documents take the value \enquote{01}. If documents with otherwise identical metadata would be issued, the value is incremented.\\
#' stage & String & The stage of proceedings in contentious jurisdiction, coded based on the title page (primary), or a close reading of the findings (secondary). Possible values are \enquote{PO} (preliminary objections), \enquote{ME} (merits), \enquote{IN} (intervention) and \enquote{CO} (compensation). Please note that the ICJ is very inconsistent in how it classifies admissibility; it can occur in the same document either together with a decision on jurisdiction or a decision on the merits. I have chosen to code pure admissibility decisions as \enquote{ME} (e.g. Second Phase of Nottebohm). In general all of the above types of decisions can occur in the same document. I therefore  do not recommend this variable for computational analysis unless great care is taken to understand its limitations. Currently only judgments are coded, orders will be added in the future.\\
#' opinion & Integer & A sequential number assigned to each opinion. Majority opinions are always coded \enquote{00}. Minority opinions begin with \enquote{01} and ascend to the maximum number of minority opinions.\\
#' language & String & The language of the document as a two-letter ISO 639-1 code. This data set contains documents in the languages English (\enquote{EN}) and French (\enquote{FR}).\\
#' year & Integer & (CSV only) The year the document was issued. The format is YYYY.\\
#' minority & Integer & (CSV only) This variable indicates whether the document is a majority (0) or minority (1) opinion.\\
#' nchars & Integer & (CSV only) The number of characters in a given document.\\
#' ntokens & Integer & (CSV only) The number of tokens (an arbitrary character sequence bounded by whitespace) in a given document. This metric can vary significantly depending on tokenizer and parameters used. This count was generated based on plain tokenization with no further pre-processing (e.g. stopword removal, removal of numbers, lowercasing) applied.  Analysts should use this number not as an exact figure, but as an estimate of the order of magnitude of a given document's length. If in doubt, perform an independent calculation with the software of your choice.\\
#' ntypes & Integer & (CSV only) The number of \emph{unique} tokens. This metric can vary significantly depending on tokenizer and parameters used. This count was generated based on plain tokenization with no further pre-processing (e.g. stopword removal, removal of numbers, lowercasing) applied. Analysts should use this number not as an exact figure, but as an estimate of the order of magnitude of a given document's length. If in doubt, perform an independent calculation with the software of your choice.\\
#' nsentences & Integer & (CSV only) The number of sentences in a given document. The rules for detecting sentence boundaries are very complex and are described in \enquote{Unicode Standard Annex No 29}. This metric can vary significantly depending on tokenizer and parameters used. This count was generated based on plain tokenization with no further pre-processing (e.g. stopword removal, removal of numbers, lowercasing) applied.  Analysts should use this number not as an exact figure, but as an estimate of the order of magnitude of a given document's length. If in doubt, perform an independent calculation with the software of your choice.\\
#' version & ISO Date & (CSV only) The version of the data set  as a date in long form as per ISO-8601. The version represents the date on which the data set creation process was begun and the data was acquired from the website of the Court.\\
#' doi\_concept & String & (CSV only) The Digital Object Identifier (DOI) for the \emph{concept} of the data set. Resolving this DOI via www.doi.org allows researchers to always acquire the \emph{latest version} of the data set. The DOI is a persistent identifier suitable for stable long-term citation. Principle F1 of the FAIR Data Principles (\enquote{data are assigned globally unique and persistent identifiers}) recommends the documentation of each data set with a persistent identifier and Principle F3 its inclusion with the metadata. Even if the CSV data set is transmitted without the accompanying Codebook this allows researchers to establish provenance of the data.\\
#' doi\_version & String & (CSV only) The Digital Object Identifier (DOI) for the \emph{specific version} of the data set. Resolving this DOI via www.doi.org allows researchers to always acquire this \emph{specific version} of the data set. The DOI is a persistent identifier suitable for stable long-term citation. Principle F1 of the FAIR Data Principles (\enquote{data are assigned globally unique and persistent identifiers}) recommends the documentation of each data set with a persistent identifier and Principle F3 its inclusion with the metadata. Even if the CSV data set is transmitted without the accompanying Codebook this allows researchers to establish provenance of the data.\\
#' license & String & (CSV only) The license of the data set. In this data set the value is always \enquote{Creative Commons Zero 1.0 Universal}. Ensures compliance with FAIR data principle R1.1 (\enquote{clear and accessible data usage license}).\\

#'\bottomrule


#'\end{longtable}
#'\end{centering}




#'\newpage

#'# Applicant and Respondent Codes

#+
#'## Contentious Jurisdiction: States
#' 
#'\label{tab:countrycodes}
#' 
#'Applicants and Respondents in contentious jurisdiction are coded according to the uppercase three-letter (Alpha-3) country codes described in the ISO 3166-1 standard. The codes are taken from the version of the standard which was valid on 4 November 2020. The table below only includes those codes which are used in the data set. The regions and subregions assigned to States generally follow the UN Standard Country or Area Codes for Statistics Use, 1999 (Revision 4), also known as the M49 standard.
#' 
#'Please note that where States have ceased to exist (Soviet Union, Yugoslavia, Serbia and Montenegro, Czechoslovakia) their historical three-letter country codes from ISO 3166-1 are used. These are not part of the current ISO 3166-1 standard, but have been transitionally reserved by the ISO 3166 Maintenance Agency to ensure backwards compatibility. The four-letter ISO 3166-3 standard (\enquote{Code for formerly used names of countries}) is not used in this data set. The regions and subregions for Yugoslavia and Czechoslovakia are taken from M49 revision 2 (1982). The Soviet Union is coded as \enquote{Europe/Eastern Europe} (the M49 standard considers the SUN its own region). Serbia and Montenegro was never included in the M49 standard and has been assigned the same region and subregion as Yugoslavia.

#'\bigskip

#'\ra{1.2}

kable(table.countrycodes,
      format = "latex",
      align = 'p{1.5cm}p{4cm}p{2cm}p{6cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("ISO-3",
                    "Name",
                    "Region",
                    "Sub-Region")) %>% kable_styling(latex_options = "repeat_header")



#'\newpage
#+
#'## Advisory Jurisdiction: Entities
#' 
#'\label{tab:entities}
#' 
#'Entities who requested an advisory opinion from the \icj\ are not Applicants in the strict sense, but have been coded under this variable to reduce clutter. I have tried to choose widely used codes for each entity.
#' 
#'Note that the \emph{International Maritime Organization (IMO)} was known as the \enquote{Inter-Governmental Maritime Consultative Organization} at the time it requested the advisory opinon. I have coded it with the modern \enquote{IMO}, as the organization only underwent a change of name and its legal continuity is not in doubt.
#' 
#'I was unable to discover a well-known acronym for the \emph{Committee on Applications for Review of Administrative Tribunal Judgements} and custom-coded it as \enquote{CARAT}.

#'\bigskip

kable(table.advcodes,
      format = "latex",
      align = c("p{3cm}",
                "p{11cm}"),
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Code",
                    "Entity"))





#'\newpage
#+
#'# Linguistic Metrics

#+
#'## Explanation of Metrics

#' To better communicate the scope of the corpus and its constituent documents I provide a number of classic linguistic metrics and visualize their distributions:
#'
#'
#' \medskip
#'
#'\begin{centering}
#'\begin{longtable}{P{3.5cm}p{10.5cm}}

#'\toprule

#'Metric & Definition\\

#'\midrule

#' Characters & Characters roughly correspond to graphemes, the smallest functional unit in a writing system. The word \enquote{judge} is composed of 5 characters, for example.\\
#' Tokens & An arbitrary character sequence delimited by whitespace on both sides, e.g. it roughly corresponds to the notion of a \enquote{word}. However, due to its strictly syntactical definition it might also include arbitrary sequences of numbers or special characters.\\
#' Types & Unique tokens. If, for example, the token \enquote{human} appeared one hundred times in a given document, it would be counted as only one type. \\
#' Sentences & Corresponds approximately to the colloquial definition of a sentence. The exact rules for determining sentence boundaries are very complex and may be reviewed in \enquote{Unicode Standard: Annex No 29}.\\

#'\bottomrule

#'\end{longtable}
#'\end{centering}
#'

#'\bigskip

#+
#'## Summary Statistics

newnames <- c("Metric",
              "Total",
              "Min",
              "Quart1",
              "Median",
              "Mean",
              "Quart3",
              "Max")


setnames(stats.ling.en, newnames)
setnames(stats.ling.fr, newnames)

#'### English

kable(stats.ling.en,
      digits = 2,
      format.args = list(big.mark = ","),
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)

#'### French

kable(stats.ling.fr,
      digits = 2,
      format.args = list(big.mark = ","),
      format = "latex",
      booktabs = TRUE,
      longtable = TRUE)



#'\newpage
#'## Explanation of Diagrams

#+
#'### Distributions of Document Length

#'The diagrams in Section \ref{doclength} are combined violin and box plots. They are especially useful in visualizing distributions of quantitative variables. Their interpretation is fairly straightforward: the greater the area under the curve for a given range, the more frequent the values are in this range. The thick center line of the box indicates the median, the outer lines of the box the first and third quartiles. Whiskers extend outwards to 1.5 times the inter-quartile range (IQR). Outliers beyond 1.5 times IQR are shown as individual points.
#'
#' Please note that the x-axis is logarithmically scaled, i.e. in powers of 10. It therefore increases in a non-linear fashion. Additional sub-markings are included to assist with interpretation.


#+
#'### Most Frequent Tokens

#' A token is defined as any character sequence delimited by whitespace on both sides, e.g. it roughly corresponds to the notion of a \enquote{word}. However, due to the strictly syntactical definition tokens might also include arbitrary sequences of numbers or special characters.
#'
#' The charts in Sections \ref{toptokens-en} and \ref{toptokens-fr} show the 50 most frequent tokens for each language, weighted by both term frequency (TF) and term frequency/inverse document frequency (TF-IDF). Sequences of numbers, special symbols and a general list of frequent words for English and French (\enquote{stopwords}) were removed prior to constructing the list. For details of the calculations, please refer to the Compilation Report and/or the Source Code.
#'
#' The term frequency $\text{tf}_{td}$ is calculated as the raw count of the number of times a term $t$ appears in a document $d$.
#'
#' The term frequency/inverse document frequency $\text{tf-idf}_{td}$ for a term $t$ in a document $d$ is calculated as follows, with $N$ the total number of documents in a corpus and  $\text{df}_{t}$ being the number of documents in the corpus in which the term $t$ appears:
#' 
#'$$\text{tf-idf}_{td} = \text{tf}_{td} \times \text{log}_{10}\left(\frac{N}{\text{df}_{t}}\right)$$

#+
#'### Tokens over Time
#' The charts in Section \ref{tokenperyear} show the total output of the \icj\ for each year as the sum total of the tokens of all published decisions (judgments, advisory opinions, orders, appended opinions). These charts may give a rough estimate of the activity of the \icj , although they should be interpreted with caution, as duplicate and highly similar opinions were not removed for this simple analysis. Please refer to Section \ref{docsim} for the scope of identical and near-identical documents in the corpus.


#+
#'\newpage
#'## Distributions of Document Length


#' \label{doclength}



#+
#'### English
#' ![](ANALYSIS/CD-ICJ_EN_10_Distributions_LinguisticMetrics-1.pdf)


#+
#'### French
#' ![](ANALYSIS/CD-ICJ_FR_10_Distributions_LinguisticMetrics-1.pdf)




#'\newpage
#+
#'## Most Frequent Tokens (English)
#'\label{toptokens-en}

#+
#'### Term Frequency Weighting (TF)
#' ![](ANALYSIS/CD-ICJ_EN_13_Top50Tokens_TF-Weighting_Scatter-1.pdf)

#+
#'### Term Frequency/Inverse Document Frequency Weighting (TF-IDF)
#' ![](ANALYSIS/CD-ICJ_EN_14_Top50Tokens_TFIDF-Weighting_Scatter-1.pdf)


#'\newpage
#+
#'## Most Frequent Tokens (French)
#'\label{toptokens-fr}

#+ 
#'### Term Frequency Weighting (TF)
#' ![](ANALYSIS/CD-ICJ_FR_13_Top50Tokens_TF-Weighting_Scatter-1.pdf)

#+
#'### Term Frequency/Inverse Document Frequency Weighting (TF-IDF)
#' ![](ANALYSIS/CD-ICJ_FR_14_Top50Tokens_TFIDF-Weighting_Scatter-1.pdf)



#+
#'\newpage
#'## Tokens over Time

#'\label{tokenperyear}


#+
#'### English
#' ![](ANALYSIS/CD-ICJ_EN_05_TokensPerYear-1.pdf)

#+
#'### French
#' ![](ANALYSIS/CD-ICJ_FR_05_TokensPerYear-1.pdf)



#+
#'# Document Similarity
#'
#' \label{docsim}

#+
#'## English 
#' ![](ANALYSIS/CD-ICJ_EN_19_DocumentSimilarity_Correlation-1.pdf)
#' 
#'## French
#' ![](ANALYSIS/CD-ICJ_FR_19_DocumentSimilarity_Correlation-1.pdf)

#+
#'## Comment
#' Analysts are advised that the CD-ICJ contains a non-negligible number of highly similar to near-identical documents. This is due to the Court's long-standing practice of issuing formally different decisions for each Applicant-Respondent pair in the course of the same proceedings. A prime example of such proceedings are the *Use of Force* cases, for which the judgments are identical in content, but differ only in the names of the Parties across more than half a dozen different judgments.
#'
#' The above figures plot the number of files to be excluded as a function of correlation similarity based on a document-unigram matrix (with the removal of numbers, special symbols and stopwords, as well as lowercasing). Analysts who wish to qualitatively review this computational approach will find the IDs of presumed duplicates, together with the relevant value of correlation similarity, stored as CSV files in the \enquote{ANALYSIS} archive published with the data set (item 17). These document IDs can also easily be read into statistical software and excluded directly from analyses without having to perform one's own similarity analysis. I do, however, recommend double-checking the IDs for false positives. The document pairings and similarity scores are included in a different CSV file (also item 17).
#'
#' The choice of similarity algorithm, the threshold for marking a document as duplicate and the question of whether duplicate documents should be removed at all should be decided with respect to individual analyses. My goal is to document the Court's output as faithfully as possible and provide analysts with fair warning, as well as the opportunity to make their own choices. Please note that the manner of de-duplication will substantially affect analytical results and should be made after careful consideration of both methodology and the data.


#' 

#+
#'\newpage
#+   
#'# Metadata Frequency Tables
#' 
#' \ra{1.3}
#' 
#+
#'## By Year

#+
#'### English

#'\vspace{0.3cm}
#' ![](ANALYSIS/CD-ICJ_EN_04_Barplot_Year-1.pdf)
#'\vspace{0.3cm}

kable(table.year.en,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Year",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")

#+
#'\newpage
#+
#'### French

#'\vspace{0.3cm}
#' ![](ANALYSIS/CD-ICJ_FR_04_Barplot_Year-1.pdf)
#'\vspace{0.3cm}

kable(table.year.fr,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Year",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")


#+
#'\newpage
#+
#'## By Document Type

#+
#'### English

#'\vspace{0.3cm}
#' ![](ANALYSIS/CD-ICJ_EN_02_Barplot_Doctype-1.pdf)
#'\vspace{1cm}

kable(table.doctype.en,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("DocType",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")

#+
#'### French

#'\vspace{0.3cm}
#' ![](ANALYSIS/CD-ICJ_FR_02_Barplot_Doctype-1.pdf)
#'\vspace{1cm}

kable(table.doctype.fr,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("DocType",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")


#'\ra{1.1}
#+
#'\newpage
#+
#'## By Opinion Number

#+
#'### English

#' ![](ANALYSIS/CD-ICJ_EN_03_Barplot_Opinion-1.pdf)


kable(table.opinion.en,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Opinion Number",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")

#+
#'\newpage
#+
#'### French

#'\vspace{0.1cm}
#' ![](ANALYSIS/CD-ICJ_FR_03_Barplot_Opinion-1.pdf)
#'\vspace{0.1cm}

kable(table.opinion.fr,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Opinion Number",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")


#'\ra{1.3}

#+
#'\newpage
#+
#'## By Applicant

#+
#'### English

kable(table.applicant.en,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Applicant",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")

#+
#'\newpage
#+
#'### French

kable(table.applicant.fr,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Applicant",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")


#+
#'\newpage
#+
#'## By Respondent

#+
#'### English

kable(table.respondent.en,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Respondent",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")

#+
#'\newpage
#+
#'### French

kable(table.respondent.fr,
      format = "latex",
      align = 'P{3cm}',
      booktabs = TRUE,
      longtable = TRUE,
      col.names = c("Respondent",
                    "Documents",
                    "% Total",
                    "% Cumulative")) %>% kable_styling(latex_options = "repeat_header")












#'\newpage
#+
#'# Verification of Cryptographic Signatures
#' This Codebook automatically verifies the SHA3-512 cryptographic signatures (\enquote{hashes}) of all ZIP archives during its compilation. SHA3-512 hashes are calculated via system call to the OpenSSL library on Linux systems.
#'
#' A successful check is indicated by \enquote{Signature verified!}. A failed check will print the line \enquote{ERROR!}



#+ echo = TRUE

# Function: Test SHA3-Hashes
sha3test <- function(filename, sig){
    sig.new <- system2("openssl",
                       paste("sha3-512", filename),
                       stdout = TRUE)
    sig.new <- gsub("^.*\\= ", "", sig.new)
    if (sig == sig.new){
        return("Signature verified!")
    }else{
        return("ERROR!")
    }
}


# Import Original Signatures
input <- fread(hashfile)
filename <- input$filename
sha3.512 <- input$sha3.512


# Verify Signatures
sha3.512.result <- mcmapply(sha3test, filename, sha3.512, USE.NAMES = FALSE)


# Print Results
testresult <- data.table(filename, sha3.512.result)

kable(testresult,
      format = "latex",
      align = c("l", "r"),
      booktabs = TRUE,
      col.names = c("File",
                    "Result"))





#' \newpage


cat(readLines("CHANGELOG.md"),
    sep = "\n")







#+
#'# Strict Replication Parameters

system2("openssl", "version", stdout = TRUE)


sessionInfo()



#'\newpage
#+
#'# References
