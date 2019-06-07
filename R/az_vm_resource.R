#' Virtual machine resource class
#'
#' Class representing a virtual machine resource. In general, the methods in this class should not be called directly, nor should objects be directly instantiated from it. Use the `az_vm_template` class for interacting with VMs instead.
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_resource] class:
#' - `new(...)`: Initialize a new VM object.
#' - `start(wait=TRUE)`: Start the VM. By default, wait until the startup process is complete.
#' - `stop(deallocate=TRUE, wait=FALSE)`: Stop the VM. By default, deallocate it as well.
#' - `restart(wait=TRUE)`: Restart the VM.
#' - `run_deployed_command(command, parameters, script)`: Run a PowerShell command on the VM.
#' - `run_script(script, parameters)`: Run a script on the VM. For a Linux VM, this will be a shell script; for a Windows VM, a PowerShell script. Pass the script as a character vector.
#' - `sync_vm_status()`: Update the VM status fields in this object with information from the host.
#' - `resize(size, deallocate=FALSE, wait=FALSE)`: Resize the VM. Optionally deallocate it first (may sometimes be necessary).
#'
#' @seealso
#' [AzureRMR::az_resource],
#' [VM API reference](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines)
#' @format An R6 object of class `az_vm_resource`, inheriting from `AzureRMR::az_resource`.
#' @export
az_vm_resource <- R6::R6Class("az_vm_resource", inherit=AzureRMR::az_resource,

public=list(
    status=NULL,

    sync_vm_status=function()
    {
        get_status <- function(lst)
        {
            status <- lapply(lst, `[[`, "code")
            names(status) <- sapply(status, function(x) sub("/.*$", "", x))
            vapply(status, function(x) sub("^[^/]+/", "", x), FUN.VALUE=character(1))
        }

        self$sync_fields()

        res <- self$do_operation("instanceView", http_verb="GET")
        self$status <- get_status(res$statuses)

        self$status
    },

    start=function(wait=TRUE)
    {
        message("Starting VM '", self$name, "'")
        self$do_operation("start", http_verb="POST")
        Sys.sleep(2)
        if(wait)
        {
            for(i in 1:100)
            {
                self$sync_vm_status()
                if(length(self$status) == 2 &&
                    self$status[1] == "succeeded" &&
                    self$status[2] == "running")
                    break
                Sys.sleep(5)
            }
            if(length(self$status) < 2 ||
                self$status[1] != "succeeded" ||
                self$status[2] != "running")
                stop("Unable to start VM", call.=FALSE)
        }
    },

    restart=function(wait=TRUE)
    {
        message("Restarting VM '", self$name, "'")
        self$do_operation("restart", http_verb="POST")
        Sys.sleep(2)
        if(wait)
        {
            for(i in 1:100)
            {
                self$sync_vm_status()
                if(length(self$status) == 2 &&
                    self$status[1] == "succeeded" &&
                    self$status[2] == "running")
                    break
                Sys.sleep(5)
            }
            if(length(self$status) < 2 ||
                self$status[1] != "succeeded" ||
                self$status[2] != "running")
                stop("Unable to restart VM", call.=FALSE)
        }
    },

    stop=function(deallocate=TRUE, wait=FALSE)
    {
        msg <- "Shutting down"
        if(deallocate)
            msg <- paste(msg, "and deallocating")
        msg <- paste0(msg, " VM '", self$name, "'")
        message(msg)

        self$do_operation("powerOff", http_verb="POST")
        if(deallocate)
            self$do_operation("deallocate", http_verb="POST")
        if(wait)
        {
            for(i in 1:100)
            {
                self$sync_vm_status()
                if(length(self$status) < 2 || self$status[2] %in% c("stopped", "deallocated"))
                    break
                Sys.sleep(5)
            }
            if(length(self$status) == 2 && !(self$status[2] %in% c("stopped", "deallocated")))
                stop("Unable to shut down VM", call.=FALSE)
        }
    },

    add_extension=function(...)
    {
        stop("This function is not yet implemented", call.=FALSE)
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
            for(i in 1:100)
            {
                self$sync_vm_status()
                if(properties$hardwareProfile$vmSize == size)
                    break
                Sys.sleep(5)
            }
            if(properties$hardwareProfile$vmSize != size)
                stop("Unable to resize VM", call.=FALSE)
        }
    },

    run_deployed_command=function(command=NULL, parameters=NULL, script=NULL)
    {
        if(is_empty(command))
            stop("Must supply a command to run", call.=FALSE)
        body <- list(commandId=command, parameters=parameters, script=script)
        self$do_operation("runCommand", body=body, encode="json", http_verb="POST")
    },

    run_script=function(script=NULL, parameters=NULL)
    {
        os_prof_names <- names(self$properties$osProfile)
        windows <- any(grepl("windows", os_prof_names, ignore.case=TRUE))
        linux <- any(grepl("linux", os_prof_names, ignore.case=TRUE))
        if(!windows && !linux)
            stop("Unknown VM operating system", call.=FALSE)

        cmd <- if(windows) "RunPowerShellScript" else "RunShellScript"
        self$run_deployed_command(cmd, as.list(parameters), as.list(script))
    },

    get_public_ip_address=function()
    {
        nic <- private$get_nic()
        ip_id <- nic$properties$ipConfigurations[[1]]$properties$publicIPAddress$id
        if(is_empty(ip_id))
            return(NULL)
        ip <- az_resource$new(self$token, self$subscription, id=ip_id)
        ip$properties$ipAddress
    },

    get_private_ip_address=function()
    {
        nic <- private$get_nic()
        nic$properties$ipConfigurations[[1]]$properties$privateIPAddress
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
            exclude=c("subscription", "resource_group", "type", "name", "status", "is_synced")))
        cat(AzureRMR::format_public_methods(self))
        invisible(NULL)
    },

    # add custom deletion method to handle managed disks
    delete=function(..., confirm=TRUE, wait=TRUE)
    {
        managed_disks <- c(
            self$properties$storageProfile$osDisk$managedDisk$id,
            lapply(self$properties$storageProfile$dataDisks,
                function(x) x$managedDisk$id)
        )

        super$delete(..., confirm=confirm, wait=wait)
        if(!is_empty(managed_disks))
        {
            lapply(managed_disks, function(id)
                az_resource$
                    new(self$token, self$subscription, id=id, deployed_properties=list(NULL))$
                    delete(confirm=confirm, wait=wait)
            )
        }
    }
),

private=list(

    get_nic=function(n=1)
    {
        nic_id <- self$properties$networkProfile$networkInterfaces[[n]]$id
        if(is_empty(nic_id))
            stop("Network interface resource not found", call.=FALSE)
        az_resource$new(self$token, self$subscription, id=nic_id)
    },

    init_and_deploy=function(...)
    {
        stop("Do not use 'az_vm_resource' to create a new VM", call.=FALSE)
    }
))

