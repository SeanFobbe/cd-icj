#'# Replace Special Characters
#' This function replaces special characters with their closest equivalents in the Latin alphabet. These characters usually occur due to OCR mistakes.

f.special.replace <- function(text){
    text.out <- gsub("ﬀ",
                     "ff",
                     text)

    text.out <- gsub("ﬁ",
                     "fi",
                     text.out)

    
    text.out <- gsub("ﬂ",
                     "fl",
                     text.out)
    
    return(text.out)
}
