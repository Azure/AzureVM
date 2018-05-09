#' @export
az_vm_resource <- R6::R6Class("az_vm", inherit=AzureRMR::az_resource,

public=list(
    disks=NULL,
    status=NULL,

    sync_vm_status=function()
    {
        get_status <- function(lst)
        {
            status <- lapply(lst, `[[`, "code")
            names(status) <- sapply(status, function(x) sub("/.*$", "", x))
            vapply(status, function(x) sub("$[^/]+/", "", x), FUN.VALUE=character(1))
        }

        res <- self$do_operation(http_verb="GET", "instanceView")
        self$statuses <- get_status(res$statuses)

        disks <- named_list(res$disks)
        self$disks <- lapply(disks, function(d) get_status(d$status))

        invisible(NULL)
    },

    start=function(wait=TRUE)
    {
        message("Starting VM '", self$name, "'")
        self$do_operation(http_verb="POST", "start")
        if(wait)
        {
            for(i in 1:100)
            {
                self$sync_vm_status()
                if(self$status["PowerState"] == "running")
                    break
                Sys.sleep(5)
            }
            if(self$status["PowerState"] != "running")
                stop("Unable to start VM", call.=FALSE)
        }
    },

    stop=function(deallocate=TRUE, wait=FALSE)
    {
        msg <- "Shutting down"
        if(deallocate)
            msg <- paste(msg, "and deallocating")
        msg <- paste0(msg, " VM '", self$name, "'")
        message(msg)

        self$do_operation(http_verb="POST", "powerOff")
        if(deallocate)
            self$do_operation(http_verb="POST", "deallocate")
        if(wait)
        {
            for(i in 1:100)
            {
                self$sync_vm_status()
                if(self$status["PowerState"] != "running")
                    break
                Sys.sleep(5)
            }
            if(self$status["PowerState"] == "running")
                stop("Unable to shut down VM", call.=FALSE)
        }
    },

    add_extension=function(...) { },

    run_script=function(...) { }
),

private=list(

    init_and_deploy=function(...)
    {
        stop("Do not use 'az_vm_resource' to create a new VM", call.=FALSE)
    }
))


#' @export
is_vm <- function(object)
{
    R6::is.R6(object) && inherits(object, "az_raw_vm")
}


