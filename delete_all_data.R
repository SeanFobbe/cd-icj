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






#'## Clean up files from previous runs


delete <- list.files(pattern = "\\.pdf|\\.zip|\\.pdf|\\.csv|\\.tex|\\.log")
unlink(delete)



for (dir in dirset){
    unlink(dir, recursive = TRUE)
}

unlink("ANALYSIS", recursive = TRUE)
unlink("temp", recursive = TRUE)

