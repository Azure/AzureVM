#' Virtual machine resource class
#'
#' Class representing a virtual machine resource. In general, the methods in this class should not be called directly, nor should objects be directly instantiated from it. Use the `az_vm_template` class for interacting with VMs instead.
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_resource] class:
#' - `start(wait=TRUE)`: Start the VM. By default, wait until the startup process is complete.
#' - `stop(deallocate=TRUE, wait=FALSE)`: Stop the VM. By default, deallocate it as well.
#' - `restart(wait=TRUE)`: Restart the VM.
#' - `run_deployed_command(command, parameters, script)`: Run a PowerShell command on the VM.
#' - `run_script(script, parameters)`: Run a script on the VM. For a Linux VM, this will be a shell script; for a Windows VM, a PowerShell script. Pass the script as a character vector.
#' - `sync_vm_status()`: Check the status of the VM.
#' - `resize(size, deallocate=FALSE, wait=FALSE)`: Resize the VM. Optionally stop and deallocate it first (may sometimes be necessary).
#' - `redeploy()`: Redeploy the VM.
#' - `reimage()`: Reimage the VM.
#' - `get_public_ip_address(nic=1, config=1)`: Get the public IP address of the VM. Returns NA if the VM is shut down, or is not publicly accessible.
#' - `get_private_ip_address(nic=1, config=1)`: Get the private IP address of the VM.
#' - `get_public_ip_resource(nic=1, config=1)`: Get the Azure resource for the VM's public IP address.
#' - `get_nic(nic=1)`: Get the VM's network interface resource.
#' - `get_vnet(nic=1, config=1)`: Get the VM's virtual network resource.
#' - `get_nsg(nic=1, config=1)`: Get the VM's network security group resource. Note that an NSG can be attached to either the VM's network interface or to its virtual network subnet; if there is an NSG attached to both, this method returns a list containing the two NSG resource objects.
#' - `get_disk(disk="os")`: Get a managed disk resource attached to the VM. The `disk` argument can be "os" for the OS disk, or a number indicating the LUN of a data disk. AzureVM only supports managed disks.
#' - `add_extension(publisher, type, version, settings=list(), protected_settings=list(), key_vault_settings=list())`: Add an extension to the VM.
#' - `do_vm_operation(...)`: Carry out an arbitrary operation on the VM resource. See the `do_operation` method of the [AzureRMR::az_resource] class for more details.
#'
#' @seealso
#' [AzureRMR::az_resource], [get_vm_resource], [az_vm_template]
#'
#' [VM API reference](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines)
#' @format An R6 object of class `az_vm_resource`, inheriting from `AzureRMR::az_resource`.
#' @export
az_vm_resource <- R6::R6Class("az_vm_resource", inherit=AzureRMR::az_resource,

public=list(
    status=NULL,

    # need to record these since AzureRMR can't currently get API versions for subresources
    nic_api_version="2019-04-01",
    ip_api_version="2019-04-01",

    sync_vm_status=function()
    {
        get_status <- function(lst)
        {
            status <- lapply(lst, `[[`, "code")
            names(status) <- sapply(status, function(x) sub("/.*$", "", x))
            vapply(status, function(x) sub("^[^/]+/", "", x), FUN.VALUE=character(1))
        }

        self$sync_fields()

        res <- self$do_operation("instanceView")
        self$status <- get_status(res$statuses)

        self$status
    },

    start=function(wait=TRUE)
    {
        self$do_operation("start", http_verb="POST")
        if(wait) private$wait_for_success("start")
    },

    restart=function(wait=TRUE)
    {
        status <- self$sync_vm_status()
        self$do_operation("restart", http_verb="POST")
        if(wait) private$wait_for_success("restart")
    },

    stop=function(deallocate=TRUE, wait=FALSE)
    {
        self$do_operation("powerOff", http_verb="POST")
        if(deallocate)
            self$do_operation("deallocate", http_verb="POST")
        if(wait)
        {
            for(i in 1:100)
            {
                Sys.sleep(5)
                self$sync_vm_status()
                if(length(self$status) < 2 || self$status[2] %in% c("stopped", "deallocated"))
                    break
            }
            if(length(self$status) == 2 && !(self$status[2] %in% c("stopped", "deallocated")))
                stop("Unable to shut down VM", call.=FALSE)
        }
    },

    resize=function(size, deallocate=FALSE, wait=FALSE)
    {
        if(deallocate)
            self$stop(deallocate=TRUE, wait=TRUE)

        properties <- list(hardwareProfile=list(vmSize=size))
        self$do_operation(http_verb="PATCH",
            body=list(properties=properties), encode="json")

        if(wait)
        {
            size <- tolower(size)
            for(i in 1:100)
            {
                self$sync_vm_status()
                newsize <- tolower(properties$hardwareProfile$vmSize)
                if(newsize == size)
                    break
                Sys.sleep(5)
            }
            if(newsize != size)
                stop("Unable to resize VM", call.=FALSE)
        }
    },

    run_deployed_command=function(command, parameters=NULL, script=NULL)
    {
        body <- list(commandId=command, parameters=parameters, script=script)
        self$do_operation("runCommand", body=body, encode="json", http_verb="POST")
    },

    run_script=function(script, parameters=NULL)
    {
        os_prof_names <- names(self$properties$osProfile)
        windows <- any(grepl("windows", os_prof_names, ignore.case=TRUE))
        linux <- any(grepl("linux", os_prof_names, ignore.case=TRUE))
        if(!windows && !linux)
            stop("Unknown VM operating system", call.=FALSE)

        cmd <- if(windows) "RunPowerShellScript" else "RunShellScript"
        self$run_deployed_command(cmd, as.list(parameters), as.list(script))
    },

    get_public_ip_address=function(nic=1, config=1)
    {
        ip <- self$get_public_ip_resource(nic, config)
        if(is.null(ip) || is.null(ip$properties$ipAddress))
            return(NA_character_)

        ip$properties$ipAddress
    },

    get_private_ip_address=function(nic=1, config=1)
    {
        nic <- self$get_nic(nic)
        nic$properties$ipConfigurations[[config]]$properties$privateIPAddress
    },

    get_public_ip_resource=function(nic=1, config=1)
    {
        nic <- self$get_nic(nic)
        ip_id <- nic$properties$ipConfigurations[[config]]$properties$publicIPAddress$id
        if(is_empty(ip_id))
            return(NULL)
        az_resource$new(self$token, self$subscription, id=ip_id, api_version=self$ip_api_version)
    },

    get_nic=function(nic=1)
    {
        nic_id <- self$properties$networkProfile$networkInterfaces[[nic]]$id
        if(is_empty(nic_id))
            stop("Network interface resource not found", call.=FALSE)
        az_resource$new(self$token, self$subscription, id=nic_id, api_version=self$nic_api_version)
    },

    get_vnet=function(nic=1, config=1)
    {
        nic <- self$get_nic(nic)
        subnet_id <- nic$properties$ipConfigurations[[config]]$properties$subnet$id
        vnet_id <- sub("/subnets/[^/]+$", "", subnet_id)
        az_resource$new(self$token, self$subscription, id=vnet_id)
    },

    get_nsg=function(nic=1, config=1)
    {
        vnet <- self$get_vnet(nic, config)
        nic <- self$get_nic(nic)

        nic_nsg_id <- nic$properties$networkSecurityGroup$id
        nic_nsg <- if(!is.null(nic_nsg_id))
            az_resource$new(self$token, self$subscription, id=nic_nsg_id)
        else NULL

        # go through list of subnets, find the one where this VM is located
        found <- FALSE
        nic_id <- tolower(nic$id)
        for(sn in vnet$properties$subnets)
        {
            nics <- tolower(unlist(sn$properties$ipConfigurations))
            if(any(grepl(nic_id, nics, fixed=TRUE)))
            {
                found <- TRUE
                break
            }
        }
        if(!found)
            stop("Error locating subnet for this network configuration", call.=FALSE)

        subnet_nsg_id <- sn$properties$networkSecurityGroup$id
        subnet_nsg <- if(!is.null(subnet_nsg_id))
            az_resource$new(self$token, self$subscription, id=subnet_nsg_id)
        else NULL

        if(is.null(nic_nsg) && is.null(subnet_nsg))
            NULL
        else if(is.null(nic_nsg) && !is.null(subnet_nsg))
            subnet_nsg
        else if(!is.null(nic_nsg) && is.null(subnet_nsg))
            nic_nsg
        else(list(nic_nsg, subnet_nsg))
    },

    get_disk=function(disk="os")
    {
        id <- if(disk == "os")
            self$properties$storageProfile$osDisk$managedDisk$id
        else if(is.numeric(disk))
            self$properties$storageProfile$dataDisks[[disk]]$managedDisk$id
        else stop("Invalid disk argument: should be 'os', or the data disk number", call.=FALSE)
        az_resource$new(self$token, self$subscription, id=id)
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

    redeploy=function()
    {
        self$do_operation("redeploy", http_verb="POST")
        message("Redeployment started. Call the sync_vm_status() method to check progress.")
    },

    reimage=function()
    {
        self$do_operation("reimage", http_verb="POST")
        message("Reimage started. Call the sync_vm_status() method to check progress.")
    },

    print=function(...)
    {
        cat("<Azure virtual machine resource ", self$name, ">\n", sep="")

        osProf <- names(self$properties$osProfile)
        os <- if(any(grepl("linux", osProf))) "Linux" else if(any(grepl("windows", osProf))) "Windows" else "<unknown>"
        prov_status <- if(is_empty(self$status))
            "<unknown>"
        else paste0(names(self$status), "=", self$status, collapse=", ")

        cat("  Operating system:", os, "\n")
        cat("  Status:", prov_status, "\n")
        cat("---\n")

        cat(AzureRMR::format_public_fields(self,
            exclude=c("subscription", "resource_group", "type", "name", "status", "is_synced",
                      "nic_api_version", "ip_api_version")))
        cat(AzureRMR::format_public_methods(self))
        invisible(NULL)
    }
),

private=list(

    init_and_deploy=function(...)
    {
        stop("Do not use 'az_vm_resource' to create a new VM", call.=FALSE)
    },

    wait_for_success=function(op)
    {
        for(i in 1:1000)
        {
            Sys.sleep(5)
            self$sync_vm_status()
            if(length(self$status) == 2 &&
                self$status[1] == "succeeded" &&
                self$status[2] == "running")
                break
        }
        if(length(self$status) < 2 ||
            self$status[1] != "succeeded" ||
            self$status[2] != "running")
            stop("Unable to ", op, " VM", call.=FALSE)
    }
))

