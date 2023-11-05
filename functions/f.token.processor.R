#'# Process Corpus to Tokens
#' This function tokenizes a corpus, removes irrelevant characters, converts to lowercase and removes common stopwords for both English and French. It is intended to simulate a generic and widespread pre-processing workflow in natural language processing.


f.token.processor <- function(corpus){
    tokens <- tokens(corpus,
                     remove_numbers = TRUE,
                     remove_punct = TRUE,
                     remove_symbols = TRUE,
                     remove_separators = TRUE)
    tokens <- tokens_tolower(tokens)
    tokens <- tokens_remove(tokens,
                            pattern = c(stopwords("english"),
                                        stopwords("french")))
    return(tokens)
}

