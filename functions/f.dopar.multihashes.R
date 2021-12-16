#'# f.dopar.multihashes
#' This function parallelizes computation of both SHA2-256 and SHA3-512 hashes for an arbitrary number of files. It returns a data frame of file names, SHA2-256 hashes and SHA3-512 hashes.


#+
#'## Required Arguments


#' @param x A vector of filenames. Should be located in the working directory.


#+
#'## Required: OpenSSL System Library
#' The function requires the existence of the OpenSSL library on the system. This is because the openssl package for R does not provide SHA 3 capabilities yet.

#'# Required Packages

library(doParallel)

#'# Requires system libraries

## openssl





f.dopar.multihashes <- function(x,
                                threads = detectCores()){
    
    print(paste("Parallel processing using", threads, "threads."))

    begin <- Sys.time()
    
    cl <- makeForkCluster(threads)
    registerDoParallel(cl)

    multihashes <- foreach(filename = x,
                           .errorhandling = 'pass',
                           .combine = 'rbind') %dopar% {
                               
                               sha2.256 <- system2("openssl",
                                                   paste("sha256",
                                                         filename),
                                                   stdout = TRUE)
                               
                               sha2.256 <- gsub("^.*\\= ",
                                                "",
                                                sha2.256)
                               
                               sha3.512 <- system2("openssl",
                                                   paste("sha3-512",
                                                         filename),
                                                   stdout = TRUE)
                               
                               sha3.512 <- gsub("^.*\\= ",
                                                "",
                                                sha3.512)
                               
                               out <- data.frame(filename,
                                                 sha2.256,
                                                 sha3.512)
                               return(out)
                           }
    stopCluster(cl)

    end <- Sys.time()
    duration <- end - begin
    
    print(paste0("Processed ",
                  length(x),
                  " files. Runtime was ",
                  round(duration,
                        digits = 2),
                  " ",
                  attributes(duration)$units,
                  "."))
    
    return(multihashes)
    
}
