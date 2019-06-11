#' @export
az_vmss_resource <- R6::R6Class("az_vmss_resource", inherit=AzureRMR::az_resource,

public=list(
    status=NULL,

    sync_vmss_status=function(id=NULL)
    {
        instances <- self$list_instances()
        if(!is.null(id))
            instances <- instances[as.character(id)]

        statuses <- private$vm_map(id, function(res)
        {
            status <- res$sync_vm_status()
            if(length(status) < 2)
                status <- c(status, NA)
            status
        })

        self$status <- data.frame(id=names(statuses), do.call(rbind, statuses), stringsAsFactors=FALSE)
        row.names(self$status) <- NULL
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
    },

    get_vm_public_ip_addresses=function(id=NULL, nic=1, config=1)
    {
        private$vm_map(id, function(vm) vm$get_public_ip_address(nic, config))
    },

    get_vm_private_ip_addresses=function(id=NULL, nic=1, config=1)
    {
        private$vm_map(id, function(vm) vm$get_private_ip_address(nic, config))
    },

    run_deployed_command=function(id=NULL, command=NULL, parameters=NULL, script=NULL)
    {
        private$vm_map(id, function(vm) vm$run_deployed_command(command, parameters, script))
    },

    run_script=function(id=NULL, script=NULL, parameters=NULL)
    {
        private$vm_map(id, function(vm) vm$run_script(script, parameters))
    },

    reimage=function(id=NULL, datadisks=FALSE)
    {
        op <- if(datadisks) "reimageall" else "reimage"
        if(is.null(id))
            self$do_operation(op, http_verb="POST")
        else private$vm_map(id, function(vm) vm$do_operation(op, http_verb="POST"))
    },

    redeploy=function(id=NULL)
    {
        if(is.null(id))
            self$do_operation("redeploy", http_verb="POST")
        else private$vm_map(id, function(vm) vm$do_operation("redeploy", http_verb="POST"))
    },

    mapped_vm_operation=function(..., id=NULL)
    {
        private$vm_map(id, function(vm) vm$do_operation(...))
    },

    add_extension=function(publisher, type, version, settings=list(),
        protected_settings=list(), key_vault_settings=list())
    {
        name <- gsub("[[:punct:]]", "", type)
        op <- file.path("extensions", name)
        props <- list(
            publisher=publisher,
            type=type,
            typeHandlerVersion=version,
            autoUpgradeMinorVersion=TRUE,
            settings=settings
        )

        if(!is_empty(protected_settings))
            props$protectedSettings <- protected_settings
        if(!is_empty(key_vault_settings))
            props$protectedSettingsFromKeyVault <- key_vault_settings

        self$do_operation(op, body=list(properties=props), http_verb="PUT")
    }
),

private=list(

    make_vm_resource=function(params)
    {
        params$instanceId <- NULL
        obj <- az_vm_resource$new(self$token, self$subscription, deployed_properties=params)
        obj$nic_api_version <- "2018-10-01"
        obj
    },

    vm_map=function(id, f)
    {
        vms <- self$list_instances()
        if(!is.null(id))
            vms <- vms[as.character(id)]
        lapply(vms, f)
    }
))
