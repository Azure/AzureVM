#' Virtual machine template class
#'
#' Class representing a virtual machine template. This class keeps track of all resources that are created as part of deploying a VM, and exposes methods for managing it. You should use this class for all VM interactions.
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_template] class:
#' - `new(...)`: Initialize a new VM object. See 'Initialization' for more details.
#' - `start(wait=TRUE)`: Start the VM. By default, wait until the startup process is complete.
#' - `stop(deallocate=TRUE, wait=FALSE)`: Stop the VM. By default, deallocate it as well.
#' - `restart(wait=TRUE)`: Restart the VM.
#' - `run_deployed_command(command, parameters, script)`: Run a PowerShell command on the VM.
#' - `run_script(script, parameters)`: Run a script on the VM. For a Linux VM, this will be a shell script; for a Windows VM, a PowerShell script. Pass the script as a character vector.
#' - `sync_vm_status()`: Update the VM status fields in this object with information from the host.
#'
#' @section Fields:
#' The following fields are available, in addition to those provided by the `AzureRMR::az_template` class:
#' - `disks`: The status of any attached disks.
#' - `ip_address`: The IP address of the VM. NULL if the VM is currently deallocated.
#' - `dns_name`: The fully qualified domain name of the VM.
#' - `status`: The status of the VM. This is a vector containing up to two elements: the provisioning state, and the power state. 
#'
#' @details
#' A virtual machine in Azure is actually a collection of resources, including any and all of the following:
#' - Storage account
#' - Network interface
#' - Network security group
#' - Virtual network
#' - IP address
#' - The VM itself
#'
#' By wrapping the deployment template used to create a VM, the `az_vm_template` class allows managing all of these resources as a single unit.
#'
#' @section Initialization:
#' Initializing a new object of this class can either retrieve an existing VM template, or deploy a new VM template on the host. Generally, the best way to initialize an object is via the `get_vm`, `create_vm` or `list_vms` methods of the [az_subscription] and [az_resource_group] class, which handle the details automatically.
#'
#' A new VM can be created in _exclusive_ mode, meaning a new resource group is created solely to hold the VM. This simplifies deleting a VM considerably, as deleting the resource group will also automatically delete all the VM's resources. This can be done asynchronously, meaning that the `delete()` method returns immediately while the process continues on the host. Otherwise, deleting a VM will explicitly delete each of its resources, a task that must be done synchronously to allow for dependencies.
#'
#' @seealso
#' [AzureRMR::az_resource], [create_vm], [get_vm]
#' [VM API reference](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines)
#' @format An R6 object of class `az_vm_template`, inheriting from `AzureRMR::az_template`.
#' @export
az_vm_template <- R6::R6Class("az_vm_template", inherit=AzureRMR::az_template,

public=list(
    disks=NULL,
    status=NULL,
    ip_address=NULL,
    dns_name=NULL,

    initialize=function(token, subscription, resource_group, name, location, os=c("Windows", "Ubuntu"),
                        size="Standard_DS3_v2", username, passkey, userauth_type=c("password", "key"),
                        template, parameters, ..., wait=TRUE)
    {
        # if no parameters were supplied, we want to retrieve an existing VM
        existing_vm <- missing(location) && missing(size) && missing(os) &&
                       missing(username) && missing(userauth_type) && missing(passkey) &&
                       missing(template) && missing(parameters) && is_empty(list(...))

        if(!existing_vm) # we want to deploy
        {
            os <- match.arg(os)
            userauth_type <- match.arg(userauth_type)

            if(missing(parameters) && (missing(username) || missing(passkey)))
                stop("Must supply login username and password/private key", call.=FALSE)

            # find template given input args
            if(missing(template))
            {
                template <- private$get_template(os, userauth_type)
                template <- system.file("templates", paste0(template, ".json"), package="AzureVM")
            }

            # convert input args into parameter list for template
            if(missing(parameters))
                parameters <- private$make_param_list(name, username, userauth_type, passkey, size, template)

            super$initialize(token, subscription, resource_group, name, template, parameters, ..., wait=wait)

            if(!wait)
            {
                message("Deployment started. Call the sync_vm_status() method ",
                        "when deployment is complete to initialise the VM")
                return(NULL)
            }
        }
        else super$initialize(token, subscription, resource_group, name)

        private$vm <- az_vm_resource$new(self$token, self$subscription, self$resource_group,
            type="Microsoft.Compute/virtualMachines", name=self$name)

        # get the hostname/IP address for the VM
        outputs <- unlist(self$properties$outputResources)
        ip <- az_resource$new(self$token, self$subscription,
            id=grep("publicIPAddresses/.+$", outputs, ignore.case=TRUE, value=TRUE))$properties
        self$ip_address <- ip$ipAddress
        self$dns_name <- ip$dnsSettings$fqdn

        private$exclusive_group <- self$properties$mode == "Complete"
        NULL
    },

    sync_vm_status=function()
    {
        if(is_empty(private$vm) || is_empty(self$status) || tolower(self$status[1]) != "succeeded")
        {
            res <- try(self$initialize(self$token, self$subscription, self$resource_group, self$name), silent=TRUE)
            if(inherits(res, "try-error"))
            {
                message("VM deployment in progress")
                return(invisible(NULL))
            }
        }

        private$vm$sync_vm_status()
        self$disks <- private$vm$disks
        self$status <- private$vm$status
        invisible(NULL)
    },

    start=function(wait=TRUE)
    {
        private$get_vm()$start(wait=wait)
        self$sync_vm_status()
    },

    stop=function(deallocate=TRUE, wait=TRUE)
    {
        private$get_vm()$stop(deallocate=deallocate, wait=wait)
        self$sync_vm_status()
    },

    restart=function(wait=TRUE)
    {
        private$get_vm()$restart(wait=wait)
        self$sync_vm_status()
    },

    delete=function(confirm=TRUE, free_resources=TRUE)
    {
        if(private$exclusive_group)
        {
            if(confirm && interactive())
            {
                msg <- paste0("Do you really want to delete VM and resource group '", self$name, "'? (y/N) ")
                yn <- readline(msg)
                if(tolower(substr(yn, 1, 1)) != "y")
                    return(invisible(NULL))
            }
            az_resource_group$new(self$token, self$subscription, self$resource_group)$delete(confirm=FALSE)
        }
        else super$delete(confirm=confirm, free_resources=free_resources)
    },

    add_extension=function(...)
    {
        private$get_vm()$add_extension(...)
    },

    run_deployed_command=function(...)
    {
        private$get_vm()$run_deployed_command(...)
    },

    run_script=function(...)
    {
        private$get_vm()$run_script(...)
    },

    print=function(...)
    {
        cat("<Azure virtual machine ", self$name, ">\n", sep="")

        osProf <- names(private$vm$properties$osProfile)
        os <- if(any(grepl("linux", osProf))) "Linux" else if(any(grepl("windows", osProf))) "Windows" else "<unknown>"
        exclusive <- private$exclusive_group
        prov_status <- if(is_empty(self$status))
            "<unknown>"
        else paste0(names(self$status), "=", self$status, collapse=", ")

        cat("  Operating system:", os, "\n")
        cat("  Exclusive resource group:", exclusive, "\n")
        cat("  Domain name:", if(is_empty(self$dns_name)) "<none>" else self$dns_name, "\n")
        cat("  Status:", prov_status, "\n")
        cat("---\n")

        cat(format_public_fields(self,
            exclude=c("subscription", "resource_group", "name", "dns_name", "status")))
        cat(format_public_methods(self))
        invisible(NULL)
    }
),

private=list(
    exclusive_group=NULL,
    vm=NULL,

    get_vm=function()
    {
        if(is_empty(private$vm))
            stop("VM deployment in progress", call.=FALSE)
        private$vm
    },

    get_template=function(os, userauth_type)
    {
        if(os == "Ubuntu")
        {
            if(userauth_type == "password")
                "ubuntu_dsvm"
            else "ubuntu_dsvm_key"
        }
        else "win2016_dsvm"
    },
    
    # params for VM templates generally require lists of (value=x) rather than vectors as inputs
    make_param_list=function(name, username, userauth_type, passkey, size, template)
    {
        template <- tools::file_path_sans_ext(basename(template))
        parm_map <- param_mappings[[template]]
        # TODO: match by argname, not position
        params <- lapply(c(username, passkey, name, size), function(x) list(value=x))
        names(params) <- parm_map
        params
    }
))


#' Is an object an Azure VM template
#'
#' @param object an R object.
#'
#' @details
#' This function returns TRUE only for an object representing a VM template deployment. In particular, it returns FALSE for a raw VM resource.
#'
#' @return
#' A boolean.
#' @export
is_vm_template <- function(object)
{
    R6::is.R6(object) && inherits(object, "az_vm_template")
}
