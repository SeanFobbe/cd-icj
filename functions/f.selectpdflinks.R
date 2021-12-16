#'# Select PDF Links

#' This function extracts from a general set of links from the ICJ website only those links which indicate monolingual case-related documents (by excluding bilingual documents).
#'
#' It is specific to the ICJ website and will not generalize without modification.


f.selectpdflinks <- function(links){
    temp <- grep ("case-related",
                  links,
                  ignore.case = TRUE,
                  value = TRUE)
    out <- grep ("BI.pdf",
                 temp,
                 ignore.case = TRUE,
                 invert = TRUE,
                 value = TRUE)
    return(out)
}
