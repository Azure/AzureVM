#' Virtual machine scaleset resource class
#'
#' Class representing a virtual machine scaleset resource. In general, the methods in this class should not be called directly, nor should objects be directly instantiated from it. Use the `az_vmss_template` class for interacting with scalesets instead.
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_template] class.
#' - `sync_vmss_status`: Check the status of the scaleset.
#' - `list_instances()`: Return a list of [az_vm_resource] objects, one for each VM instance in the scaleset. Note that if the scaleset has a load balancer attached, the number of instances will vary depending on the load.
#' - `get_instance(id)`: Return a specific VM instance in the scaleset.
#' - `start(id=NULL, wait=FALSE)`: Start the scaleset. In this and the other methods listed here, `id` can be an optional character vector of instance IDs; if supplied, only carry out the operation for those instances.
#' - `restart(id=NULL, wait=FALSE)`: Restart the scaleset.
#' - `stop(deallocate=TRUE, id=NULL, wait=FALSE)`: Stop the scaleset.
#' - `get_public_ip_address()`: Get the public IP address of the scaleset (technically, of the load balancer). If the scaleset doesn't have a load balancer attached, returns NA.
#' - `get_vm_public_ip_addresses(id=NULL, nic=1, config=1)`: Get the public IP addresses for the instances in the scaleset. Returns NA if the instances are not publicly accessible.
#' - `get_vm_private_ip_addresses(id=NULL, nic=1, config=1)`: Get the private IP addresses for the instances in the scaleset.
#' - `run_deployed_command(command, parameters=NULL, script=NULL, id=NULL)`: Run a PowerShell command on the instances in the scaleset.
#' - `run_script(script, parameters=NULL, id=NULL)`: Run a script on the VM. For a Linux VM, this will be a shell script; for a Windows VM, a PowerShell script. Pass the script as a character vector.
#' - `reimage(id=NULL, datadisks=FALSE)`: Reimage the instances in the scaleset. If `datadisks` is TRUE, reimage any attached data disks as well.
#' - `redeploy(id=NULL)`: Redeploy the instances in the scaleset.
#' - `mapped_vm_operation(..., id=NULL)`: Carry out an arbitrary operation on the instances in the scaleset. See the `do_operation` method of the [AzureRMR::az_resource] class for more details.
#' - `add_extension(publisher, type, version, settings=list(), protected_settings=list(), key_vault_settings=list())`: Add an extension to the scaleset.
#' - `do_vmss_operation(...)` Carry out an arbitrary operation on the scaleset resource (as opposed to the instances in the scaleset).
#'
#' @details
#' A single virtual machine scaleset in Azure is actually a collection of resources, including any and all of the following.
#' - Network security group (Azure resource type `Microsoft.Network/networkSecurityGroups`)
#' - Virtual network (Azure resource type `Microsoft.Network/virtualNetworks`)
#' - Load balancer (Azure resource type `Microsoft.Network/loadBalancers`)
#' - Public IP address (Azure resource type `Microsoft.Network/publicIPAddresses`)
#' - Autoscaler (Azure resource type `Microsoft.Insights/autoscaleSettings`)
#' - The scaleset itself (Azure resource type `Microsoft.Compute/virtualMachineScaleSets`)
#'
#' By wrapping the deployment template used to create these resources, the `az_vmss_template` class allows managing them all as a single entity.
#'
#' @section Instance operations:
#' AzureVM has the ability to parallelise scaleset instance operations using a pool of background processes. This can lead to significant speedups when working with scalesets with high instance counts. The pool is created automatically the first time that it is required, and remains persistent for the session. For more information, see [init_pool].
#'
#' The `id` argument lets you specify a subset of instances on which to carry out an operation. This can be a character vector of instance IDs; a list of instance objects such as returned by `list_instances`; or a single instance object. The default (NULL) is to carry out the operation on all instances.
#'
#' @seealso
#' [AzureRMR::az_resource], [get_vm_scaleset_resource], [az_vmss_template], [init_pool]
#'
#' [VM scaleset API reference](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachinescalesets)
#' @format An R6 object of class `az_vmss_resource`, inheriting from `AzureRMR::az_resource`.
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
        colnames(self$status) <- c("id", "ProvisioningState", "PowerState")
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
        body <- if(!is.null(id)) list(instanceIds=I(as.character(id))) else NULL
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
        body <- if(!is.null(id)) list(instanceIds=I(as.character(id))) else NULL
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
        body <- if(!is.null(id)) list(instanceIds=I(as.character(id))) else NULL
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
        unlist(private$vm_map(id, function(vm) vm$get_public_ip_address(nic, config)))
    },

    get_vm_private_ip_addresses=function(id=NULL, nic=1, config=1)
    {
        unlist(private$vm_map(id, function(vm) vm$get_private_ip_address(nic, config)))
    },

    run_deployed_command=function(command, parameters=NULL, script=NULL, id=NULL)
    {
        private$vm_map(id, function(vm) vm$run_deployed_command(command, parameters, script))
    },

    run_script=function(script, parameters=NULL, id=NULL)
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
    },

    print=function(...)
    {
        cat("<Azure virtual machine scaleset resource ", self$name, ">\n", sep="")

        osProf <- names(self$properties$virtualMachineProfile$osProfile)
        os <- if(any(grepl("linux", osProf))) "Linux" else if(any(grepl("windows", osProf))) "Windows" else "<unknown>"

        cat("  Operating system:", os, "\n")
        cat("  Status:\n")
        if(is_empty(self$status))
            cat("    <unknown>\n")
        else
        {
            status <- head(self$status)
            row.names(status) <- paste0("     ", row.names(status))
            print(status)
            if(nrow(self$status) > nrow(status))
            cat("    ...\n")
        }
        cat("---\n")

        exclude <- c("subscription", "resource_group", "type", "name", "status")

        cat(AzureRMR::format_public_fields(self, exclude=exclude))
        cat(AzureRMR::format_public_methods(self))
        invisible(NULL)
    }
),

private=list(

    init_and_deploy=function(...)
    {
        stop("Do not use 'az_vmss_resource' to create a new VM scaleset", call.=FALSE)
    },

    make_vm_resource=function(params)
    {
        params$instanceId <- NULL
        obj <- az_vm_resource$new(self$token, self$subscription, deployed_properties=params)
        obj$nic_api_version <- "2018-10-01"
        obj$ip_api_version <- "2018-10-01"

        # make type and name useful
        obj$type <- self$type
        obj$name <- file.path(self$name, "virtualMachines", basename(params$id))
        obj
    },

    vm_map=function(id, f)
    {
        vms <- if(is.null(id))
            self$list_instances()
        else if(is.list(id) && all(sapply(id, is_vm_resource)))
            id
        else if(is_vm_resource(id))
            structure(list(id), names=basename(id$id))
        else self$list_instances()[as.character(id)]

        if(length(vms) < 2 || getOption("azure_vm_maxpoolsize") == 0)
            return(lapply(vms, f))

        init_pool(length(vms))
        parallel::parLapply(.AzureVM$pool, vms, f)
    }
))
