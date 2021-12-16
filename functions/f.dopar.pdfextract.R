#'# f.dopar.pdfextract: Parallelized Extraction of text from PDF files
#' This function parallelizes the extraction of text from each PDF file and saves the results as TXT files. Only the file extension is modified.


#+
#'## Required Arguments


#' @param x A vector of PDF filenames. Should be located in the working directory.




#'## Required Packages

library(doParallel)
library(pdftools)

#'## Function

f.dopar.pdfextract <- function(x,
                               threads = detectCores()){

    begin.extract <- Sys.time()
    
    print(paste("Parallel processing using", threads, "threads. Begin at", begin.extract))

    
    cl <- makeForkCluster(threads)
    registerDoParallel(cl)

    newnames <- gsub("\\.pdf",
                     "\\.txt",
                     x)

    result <- foreach(i = seq_along(x),
                      .errorhandling = 'pass') %dopar% {            

                          ## Extract text layer from PDF
                          pdf.extracted <- pdf_text(x[i])

                          ## Write TXT to Disk
                          write.table(pdf.extracted,
                                      newnames[i],
                                      quote = FALSE,
                                      row.names = FALSE,
                                      col.names = FALSE)
                   }
    stopCluster(cl)
    
    end.extract <- Sys.time()
    duration.extract <- end.extract - begin.extract
    
    print(paste0("Processed ",
                  length(result),
                  " files. Runtime was ",
                  round(duration.extract,
                        digits = 2),
                  " ",
                  attributes(duration.extract)$units,
                  ". Ended at ",
                 end.extract, "."))

    return(result)

}


