#'# f.dopar.pagenums: Parallelized Computation of the length (in pages) of PDF files
#' This function computes the maximum number of pages for each PDF file. Ideally used with sum() to get the total number of pages of all PDF files in a folder. 


#+
#'## Required Arguments


#' @param x A vector of PDF filenames. Should be located in the working directory.


#'## Required Packages

library(doParallel)
library(pdftools)

#'## Function
    

f.dopar.pagenums <- function(x,
                             sum = FALSE,
                             threads = detectCores()){
    
    print(paste("Parallel processing using", threads, "threads."))

    cl <- makeForkCluster(threads)
    registerDoParallel(cl)

    pagenums <- foreach(filename = x,
                        .combine = 'c',
                        .errorhandling = 'remove',
                        .inorder = TRUE) %dopar% {
                            pdf_length(filename)
                        }
    stopCluster(cl)

    if (sum == TRUE){
        sum.out <- sum(pagenums)
        print(paste("Total number of pages:", sum.out))
        return(sum.out)
    }else{
        return(pagenums)
    }
    
}

