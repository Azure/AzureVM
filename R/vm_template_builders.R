add_template_parameters.vm_config <- function(config, ...)
{
    add_param <- function(...)
    {
        new_params <- lapply(list(...), function(obj) list(type=obj))
        params <<- c(params, new_params)
    }

    params <- tpl_parameters_default

    if(config$keylogin)
        add_param(sshKeyData="string")
    else add_param(adminPassword="securestring")

    if(inherits(config$image, "image_marketplace"))
        add_param(imagePublisher="string", imageOffer="string", imageSku="string", imageVersion="string")
    else add_param(imageId="string")

    if(inherits(config$nsg, "nsg_config"))
        add_param(nsgrules="array")

    if(length(config$datadisks) > 0)
        add_param(dataDisks="array", dataDiskResources="array")

    params
}


add_template_variables.vm_config <- function(config, ...)
{
    vars <- tpl_variables_default
    for(res in c("nsg", "ip", "vnet", "nic"))
    {
        obj <- config[[res]]
        # input can be a resource ID string, an AzureRMR::az_resource object, a config object, or NULL (no resource)
        if(is.character(obj))
        {
            vars[[paste0(res, "Name")]] <- basename(obj)
            vars[[paste0(res, "Id")]] <- obj
        }
        else if(is_resource(obj))
        {
            vars[[paste0(res, "Name")]] <- obj$name
            vars[[paste0(res, "Id")]] <- obj$id
        }
        else if(is.null(obj))
        {
            vars[[paste0(res, "Name")]] <- NULL
            vars[[paste0(res, "Id")]] <- NULL
            vars[[paste0(res, "Ref")]] <- NULL
        }
    }

    # if we have a vnet, extract the 1st subnet name
    if(inherits(config$vnet, "vnet_config") || is_resource(config$vnet))
        vars$subnet <- config$vnet$properties$subnets[[1]]$name

    # add any extra variables provided by the user    
    utils::modifyList(vars, config$variables)
}


add_template_resources.vm_config <- function(config, ...)
{
    nsg <- nsg_default
    ip <- ip_default
    vnet <- vnet_default
    nic <- nic_default
    vm <- vm_default

    # fixup VM properties
    n_disks <- length(config$datadisks)
    n_disk_resources <- if(n_disks > 0)
        sum(sapply(config$datadisks, function(x) !is.null(x$res_spec)))
    else 0

    if(n_disks > 0)
    {
        vm$properties$storageProfile$copy <- vm_datadisk
        if(n_disk_resources > 0)
            vm$dependsOn <- c(vm$dependsOn, "managedDiskResources")
    }

    if(config$managed)
        vm$identity <- list(type="systemAssigned")

    vm$properties$osProfile <- c(vm$properties$osProfile,
        if(config$keylogin) vm_key_login else vm_pwd_login)

    if(inherits(config$image, "image_custom"))
        vm$properties$storageProfile$imageReference <- list(id="[parameters('imageId')]")

    # fixup nsg security rule priorities
    for(i in seq_along(config$nsg$properties$securityRules))
    {
        if(is_empty(config$nsg$properties$securityRules[[i]]$properties$priority))
            config$nsg$properties$securityRules[[i]]$properties$priority <- 1000 + 10 * i
    }

    ## fixup dependencies between resources
    # vnet depends on nsg
    # nic depends on ip, vnet (possibly nsg)
    # vm depends on nic (but nic should always be created)

    existing <- sapply(config[c("nsg", "ip", "vnet", "nic")], existing_resource)
    unused <- sapply(config[c("nsg", "ip", "vnet", "nic")], is.null)
    created <- !existing & !unused

    if(!created["nsg"])
        vnet$dependsOn <- NULL

    if(unused["nsg"])
        config$vnet$properties$subnets[[1]]$properties$networkSecurityGroup <- NULL

    nic_created_depends <- created[c("ip", "vnet")]
    nic$dependsOn <- nic$dependsOn[nic_created_depends]
    if(unused["ip"])
        config$nic$properties$ipConfigurations[[1]]$properties$publicIPAddress <- NULL

    resources <- mapply(utils::modifyList,
        list(nsg, ip, vnet, nic)[created],
        config[c("nsg", "ip", "vnet", "nic")][created],
        SIMPLIFY=FALSE)

    if(n_disk_resources > 0)
        resources <- c(resources, list(disk_default))

    resources <- c(resources, list(vm))

    if(!is_empty(config$other))
        resources <- c(resources, config$other)

    resources
}


# if deployment uses an existing resource, turn it into a nested template
modify_resource <- function(resource, ...)
{
    if(!inherits(resource, "az_resource"))
        return(resource)

    reslist <- as.list(resource)[c("type", "name", "location", "kind", "sku", "properties", "identity")]
    nulls <- sapply(reslist, is.null)
    reslist <- reslist[!nulls]

    if(is.null(resource$get_api_version()))
        resource$set_api_version()
    reslist$apiVersion <- resource$get_api_version()

    tpl <- res_update_deployment
    tpl$properties$template$resources[[1]] <- utils::modifyList(reslist, list(...))

    tpl
}


# check if we are referring to an existing resource or creating a new one
existing_resource <- function(object)
{
    # can be a resource ID string or AzureRMR::az_resource object
    is.character(object) || is_resource(object)
}


