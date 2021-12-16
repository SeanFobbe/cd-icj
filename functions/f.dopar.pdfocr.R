#'# f.dopar.pdfocr: Parallelized Extraction of text from PDF files
#' This function extracts the text from scanned PDF files to separate TXT files and further creates an enhanced PDF version with new OCR text grafted to the scan. It runs in nested parallelization, with tesseract calling up to 3 or 4 threads to process a single PDF file and the number of jobs determines how many PDF files are processed in parallel. Very, very CPU intensive. Will only work on Linux.


#+
#'## Required Arguments


#' @param x A vector of PDF filenames. Should be located in the working directory.
#' @param dpi The resolution at which PDF files should be converted. Defaults to 300.
#' @param lang The languages which should be expected during the OCR step, as string. Passed directly to tesseract. Default is "eng" for English. Multiple languages possible, e.g. "eng+fra" for English and French. Order of language matters.
#' @param output The output which should be generated, as string. Passed directly to tesseract. Default is "pdf txt" for PDF and TXT output.
#' @param jobs The number of jobs which should be run in parallel. Tesseract calls up to 4 threads by itself, so it should be somewhere around the full number of cores divided by 4. This is also the default. 



#'## Required Packages

library(doParallel)

#'## Required System Libraries

## tesseract
## imagemagick


f.dopar.pdfocr <- function(x,
                           dpi = 300,
                           lang = "eng",
                           output = "pdf txt",
                           jobs = round(detectCores() / 4)){

    begin.ocr <- Sys.time()
    
    print(paste("Parallel processing running", jobs, "jobs. Begin at", begin.ocr))

    cl <- makeForkCluster(jobs)
    registerDoParallel(cl)
    

    result <- foreach(file = x,
                      .combine = 'c') %dopar% {
                          
                          name.tiff <- gsub("\\.pdf",
                                            "\\.tiff",
                                            file)
                          
                          name.out <- gsub("\\.pdf",
                                           "_TESSERACT",
                                           file)
                          
                          system2("convert",
                                  paste("-density",
                                        dpi,
                                        "-depth 8 -compress LZW -strip -background white -alpha off",
                                        file,
                                        name.tiff))
                          
                          system2("tesseract",
                                  paste(name.tiff,
                                        name.out,
                                        "-l",
                                        lang,
                                        output))
                          
                          unlink(name.tiff)
                      }

    stopCluster(cl)
    
    end.ocr <- Sys.time()
    duration.ocr <- end.ocr - begin.ocr
    
    print(paste0("Processed ",
                  length(result),
                  " files. Runtime was ",
                  round(duration.ocr,
                        digits = 2),
                  " ",
                  attributes(duration.ocr)$units,
                  ". Ended at ",
                 end.ocr, "."))
    
    return(result)

}
