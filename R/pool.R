#' Parallelise operations on VM scaleset instances
#'
#' @param connections The number of concurrent connections to support, which translates into the number of background R processes to create. Each connection requires a separate R process, so limit this is you are low on memory.
#' @param restart For `init_pool`, whether to terminate an already running pool first.
#' @param ... Other arguments passed on to `parallel::makeCluster`.
#'
#' @details
#' AzureVM can parallelise operations on scaleset instances by utilizing a pool of R processes in the background. This can lead to significant speedups when working with scalesets with high instance counts. The pool is created automatically the first time that it is required, or it can be (re)created by calling `init_pool` manually. It remains persistent for the session or until terminated by `delete_pool`.
#'
#' If `init_pool` is called and the current pool is smaller than `connections`, it is resized. The size of the pool can be controlled by the global options `azure_vm_minpoolsize` and `azure_vm_maxpoolsize`, which have default values of 2 and 10 respectively. To disable parallel operations, set `options(azure_vm_maxpoolsize=0)`.
#'
#' @seealso
#' [az_vmss_template], [parallel::makeCluster]
#' @rdname pool
#' @aliases azure_vm_minpoolsize azure_vm_maxpoolsize
#' @export
init_pool <- function(connections, restart=FALSE, ...)
{
    if(restart)
        delete_pool()

    minsize <- getOption("azure_vm_minpoolsize")
    maxsize <- getOption("azure_vm_maxpoolsize")
    size <- min(max(connections, minsize), maxsize)
    if(size < 1)
        stop("Invalid pool size ", size, call.=FALSE)

    if(!exists("pool", envir=.AzureVM) || length(.AzureVM$pool) < size)
    {
        delete_pool()
        message("Creating background pool")
        .AzureVM$pool <- parallel::makeCluster(size)
    }
    else
    {
        # restore original state, set working directory to master working directory
        parallel::clusterCall(.AzureVM$pool, function(wd)
        {
            setwd(wd)
            rm(list=ls(all.names=TRUE), envir=.GlobalEnv)
        }, wd=getwd())
    }

    invisible(NULL)
}


#' @rdname pool
#' @export
delete_pool <- function()
{
    if(!exists("pool", envir=.AzureVM))
        return()

    message("Deleting background pool")
    parallel::stopCluster(.AzureVM$pool)
    rm(pool, envir=.AzureVM)
}
