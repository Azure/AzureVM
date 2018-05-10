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

    run_command=function(...)
    {
        private$get_vm()$run_command(...)
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


#' @export
is_vm <- function(object)
{
    R6::is.R6(object) && inherits(object, "az_vm_template")
}
