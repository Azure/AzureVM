#' @export
az_vm_template <- R6::R6Class("az_vm_template", inherit=AzureRMR::az_template,

public=list(
    disks=NULL,
    status=NULL,

    initialize=function(token, subscription, resource_group, name=NULL, location, os=c("Windows", "Ubuntu"),
                        size="Standard_DS2_v2", username=NULL, passkey=NULL, userauth_type=c("password", "key"),
                        template, parameters, ..., exclusive_group=FALSE, wait=TRUE)
    {
        # if no parameters were supplied, we want to retrieve an existing template
        if(!(missing(location) && missing(size) && missing(os) &&
             missing(username) && missing(userauth_type) && missing(passkey)))
        {
            os <- match.arg(os)
            userauth_type <- match.arg(userauth_type)

            if(is_empty(username) || is_empty(passkey))
                stop("Must supply login username and password/private key", call.=FALSE)

            # find template given input args
            if(missing(template))
                template <- private$get_template(os, userauth_type)

            # convert input args into parameter list for template
            if(missing(parameters))
                parameters <- private$make_param_list(name, username, userauth_type, passkey, size, template)

            template <- system.file("templates", paste0(template, ".json"), package="AzureVM")
        }

        super$initialize(token, subscription, resource_group, name, template, parameters, ..., wait=wait)

        private$vm <- az_vm_resource$new(self$token, self$subscription, self$resource_group,
            type="Microsoft.Compute/virtualMachines", name=self$name)

        private$exclusive_group <- exclusive_group
        NULL
    },

    sync_vm_status=function()
    {
        private$vm$sync_vm_status()
        self$disks <- private$vm$disks
        self$status <- private$vm$status
        invisible(NULL)
    },

    start=function(wait=TRUE)
    {
        private$vm$start(wait=wait)
        self$sync_vm_status()
    },

    stop=function(deallocate=TRUE, wait=TRUE)
    {
        private$vm$stop(deallocate=deallocate, wait=wait)
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
        private$vm$add_extension(...)
    },

    run_script=function(...)
    {
        private$vm$run_script(...)
    }
),

private=list(
    exclusive_group=NULL,
    vm=NULL,

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
