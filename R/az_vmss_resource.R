#' @export
az_vmss_resource <- R6::R6Class("az_vmss_resource", inherit=AzureRMR::az_resource,

public=list(
    status=NULL,

    sync_vmss_status=function(id=NULL)
    {
        instances <- self$list_instances()
        if(!is.null(id))
            instances <- instances[as.character(id)]

        statuses <- sapply(instances, function(res) res$sync_vm_status())
        self$status <- data.frame(
            id=colnames(statuses),
            ProvisioningState=statuses[1, ],
            PowerState=statuses[2, ],
            stringsAsFactors=FALSE
        )

        self$status
    },

    list_instances=function()
    {
        lst <- named_list(get_paged_list(self$do_operation("virtualMachines")), "instanceId")
        lapply(lst, private$make_vm_resource)
    },

    get_instance=function(id)
    {
        obj <- self$do_operation(file.path("virtualMachines", id))
        private$make_vm_resource(obj)
    },

    start=function(id=NULL, wait=FALSE)
    {
        body <- if(!is.null(id)) list(instanceIds=I(id)) else NULL
        self$do_operation("start", body=body, http_verb="POST")

        if(wait)
        {
            for(i in 1:100)
            {
                Sys.sleep(5)
                status <- self$sync_vmss_status(id)
                if(all(status$PowerState == "running"))
                    break
            }
            if(!all(status$PowerState == "running"))
                stop("Unable to start VM scaleset", call.=FALSE)
        }
    },

    restart=function(id=NULL, wait=FALSE)
    {
        body <- if(!is.null(id)) list(instanceIds=I(id)) else NULL
        self$do_operation("restart", body=body, http_verb="POST")

        if(wait)
        {
            for(i in 1:100)
            {
                Sys.sleep(5)
                status <- self$sync_vmss_status(id)
                if(all(status$PowerState == "running"))
                    break
            }
            if(!all(status$PowerState == "running"))
                stop("Unable to restart VM scaleset", call.=FALSE)
        }
    },

    stop=function(deallocate=TRUE, id=NULL, wait=FALSE)
    {
        body <- if(!is.null(id)) list(instanceIds=I(id)) else NULL
        self$do_operation("powerOff", body=body, http_verb="POST")
        if(deallocate)
            self$do_operation("deallocate", body=body, http_verb="POST")

        if(wait)
        {
            for(i in 1:100)
            {
                Sys.sleep(5)
                status <- self$sync_vm_status(id)
                if(all(status$PowerState %in% c("stopped", "deallocated")))
                    break
            }
            if(length(self$status) == 2 && !(self$status[2] %in% c("stopped", "deallocated")))
                stop("Unable to shut down VM", call.=FALSE)
        }
    }
),

private=list(

    make_vm_resource=function(params)
    {
        params$instanceId <- NULL
        obj <- az_vm_resource$new(self$token, self$subscription, deployed_properties=params)
        obj$nic_api_version <- "2018-10-01"
        obj
    }
))
