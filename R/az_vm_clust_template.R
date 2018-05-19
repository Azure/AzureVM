az_vm_clust_template <- R6::R6Class("az_vm_clust_template", inherit=az_template,

public=list(
    disks=NULL,
    status=NULL,
    ip_address=NULL,
    dns_name=NULL,
    clust_size=NULL,

    initialize=function(token, subscription, resource_group, name, location, os=c("Windows", "Ubuntu"),
                        size="Standard_DS3_v2", username, passkey, userauth_type=c("password", "key"),
                        extensions=NULL, clust_size=3, template, parameters,
                        ..., wait=TRUE)
    {
        # if no parameters were supplied, we want to retrieve an existing VM
        existing_vm <- missing(location) && missing(size) && missing(os) &&
                       missing(username) && missing(userauth_type) && missing(passkey) &&
                       missing(extensions) && missing(clust_size) &&
                       missing(template) && missing(parameters) && is_empty(list(...))

        if(!existing_vm) # we want to deploy
        {
            os <- match.arg(os)
            userauth_type <- match.arg(userauth_type)

            if(missing(parameters) && (missing(username) || missing(passkey)))
                stop("Must supply login username and password/private key", call.=FALSE)

            # find template given input args
            if(missing(template))
                template <- private$get_dsvm_clust_template(os, userauth_type, extensions)

            # convert input args into parameter list for template
            if(missing(parameters))
                parameters <-
                    private$make_dsvm_clust_param_list(name, username, userauth_type, passkey, size,
                                                       extensions, clust_size, template)

            super$initialize(token, subscription, resource_group, name, template, parameters, ..., wait=wait)

            if(!wait)
            {
                message("Deployment started. Call the sync_vm_status() method ",
                        "when deployment is complete to initialise the VM")
                return(NULL)
            }
        }
        else super$initialize(token, subscription, resource_group, name)

        self$clust_size <- as.numeric(self$properties$outputs$numInstances$value)

        private$vm <- lapply(seq_len(self$clust_size), function(i)
        {
            name <- paste0(self$name, i - 1)
            az_vm_resource$new(self$token, self$subscription, self$resource_group,
                type="Microsoft.Compute/virtualMachines", name=name)
        })

        # get the hostname/IP address for the VM
        outputs <- unlist(self$properties$outputResources)
        ip_id <- grep("publicIPAddresses/.+$", outputs, ignore.case=TRUE, value=TRUE)
        ip <- lapply(ip_id, function(id)
            az_resource$new(self$token, self$subscription, id=id)$properties)

        self$ip_address <- sapply(ip, function(x) x$ipAddress)
        self$dns_name <- sapply(ip, function(x) x$dnsSettings$fqdn)

        lapply(private$vm, function(obj) obj$sync_vm_status())
        self$disks <- lapply(private$vm, "[[", "disks")
        self$status <- lapply(private$vm, "[[", "status")

        private$exclusive_group <- self$properties$mode == "Complete"
        NULL
    },

    sync_vm_status=function()
    {
        if(is_empty(private$vm) || is_empty(self$status) || tolower(self$status[[1]][1]) != "succeeded")
        {
            res <- try(self$initialize(self$token, self$subscription, self$resource_group, self$name), silent=TRUE)
            if(inherits(res, "try-error"))
            {
                message("VM deployment in progress")
                return(invisible(NULL))
            }
        }

        lapply(private$vm, function(obj) obj$sync_vm_status())
        self$disks <- lapply(private$vm, "[[", "disks")
        self$status <- lapply(private$vm, "[[", "status")
        invisible(NULL)
    },

    start=function(wait=FALSE)
    {
        private$wait_warn(wait)
        lapply(private$get_vm(), function(obj) obj$start(wait=FALSE))
        self$sync_vm_status()
    },

    stop=function(deallocate=TRUE, wait=FALSE)
    {
        private$wait_warn(wait)
        lapply(private$get_vm(), function(obj) obj$stop(deallocate=deallocate, wait=FALSE))
        self$sync_vm_status()
    },

    restart=function(wait=TRUE)
    {
        private$wait_warn(wait)
        lapply(private$get_vm(), function(obj) obj$restart(wait=FALSE))
        self$sync_vm_status()
    },

    add_extension=function(...)
    {
        lapply(private$get_vm(), function(obj) obj$add_extension(...))
    },

    run_deployed_command=function(...)
    {
        lapply(private$get_vm(), function(obj) obj$run_deployed_command(...))
    },

    run_script=function(...)
    {
        lapply(private$get_vm(), function(obj) obj$private$get_vm()$run_script(...))
    },

    delete=function(confirm=TRUE, free_resources=TRUE)
    {
        if(private$exclusive_group)
        {
            if(confirm && interactive())
            {
                msg <- paste0("Do you really want to delete VM cluster and resource group '", self$name, "'? (y/N) ")
                yn <- readline(msg)
                if(tolower(substr(yn, 1, 1)) != "y")
                    return(invisible(NULL))
            }
            az_resource_group$new(self$token, self$subscription, self$resource_group)$delete(confirm=FALSE)
        }
        else super$delete(confirm=confirm, free_resources=free_resources)
    },

    print=function(...)
    {
        header <- "<Azure virtual machine "
        if(self$clust_size > 1)
            header <- paste0(header, "cluster ")
        cat(header, self$name, ">\n", sep="")

        osProf <- names(private$vm[[1]]$properties$osProfile)
        os <- if(any(grepl("linux", osProf))) "Linux" else if(any(grepl("windows", osProf))) "Windows" else "<unknown>"
        exclusive <- private$exclusive_group
        dns_label <- if(self$clust_size == 1) "Domain name:" else "Domain names:"
        dns_names <- if(is_empty(self$dns_name))
            paste0("  ", dns_label, " <none>")
        else strwrap(paste(dns_label, paste0(self$dns_name, collapse=", ")),
                     width=0.8*getOption("width"), indent=2, exdent=4)

        cat("  Operating system:", os, "\n")
        cat("  Exclusive resource group:", exclusive, "\n")
        cat(paste0(dns_names, collapse="\n"), "\n", sep="")
        cat("  Status:")

        if(is_empty(self$status))
            cat(" <unknown>\n")
        else
        {
            prov_status <- do.call(rbind.data.frame, self$status)
            prov_status[[1]] <- paste0("    ", as.character(prov_status[[1]]))
            names(prov_status) <- names(self$status[[1]])
            names(prov_status)[1] <- paste0("    ", names(prov_status)[1])
            cat("\n")
            print(prov_status, row.names=FALSE, right=FALSE)
        }

        cat("---\n")

        exclude <- c("subscription", "resource_group", "name", "dns_name", "status")
        if(self$clust_size == 1)
            exclude <- c(exclude, "clust_size")
        cat(format_public_fields(self, exclude=exclude))
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

    wait_warn=function(wait)
    {
        if(wait)
            warning("'wait' argument not used", call.=FALSE)
    },

    get_dsvm_clust_template=function(os, userauth_type, clust_size, extensions)
    {

        if(os == "Ubuntu")
            template <- "ubuntu_dsvm"
        else if(os == "Windows")
            template <- "win2016_dsvm"
        else stop("Unknown OS: ", os, call.=FALSE)

        if(clust_size > 1)
            template <- paste0(template, "_cl")

        if(userauth_type == "key")
            template <- paste0(template, "_key")

        if(!is_empty(extensions))
            template <- paste0(template, "_ext")

        template <- system.file("templates", paste0(template, ".json"), package="AzureVM")
        if(template == "")
            stop("Unsupported combination of parameters", call.=FALSE)
        template
    },

    make_dsvm_clust_param_list=function(name, username, userauth_type, passkey, size, extensions, clust_size, template)
    {
        template <- tools::file_path_sans_ext(basename(template))
        parm_map <- param_mappings[[template]]

        params <- lapply(c(username, passkey, name, size, clust_size), function(x) list(value=x))
        names(params) <- parm_map
        params
    }
))

