add_template_parameters.vmss_config <- function(config, ...)
{
    add_param <- function(...)
    {
        new_params <- lapply(list(...), function(obj) list(type=obj))
        params <<- c(params, new_params)
    }

    params <- sstpl_parameters_default

    if(config$options$keylogin)
        add_param(sshKeyData="string")
    else add_param(adminPassword="securestring")

    if(inherits(config$image, "image_marketplace"))
        add_param(imagePublisher="string", imageOffer="string", imageSku="string", imageVersion="string")
    else add_param(imageId="string")

    params
}


add_template_variables.vmss_config <- function(config, ...)
{
    vars <- sstpl_variables_default
    for(res in c("nsg", "vnet", "lb", "ip", "as"))
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


add_template_resources.vmss_config <- function(config, ...)
{
    nsg <- nsg_default
    vnet <- vnet_default
    lb <- lb_default
    ip <- ip_default
    as <- as_default
    vmss <- vmss_default

    # fixup VMSS properties
    if(config$options$managed)
        vmss$identity <- list(type="systemAssigned")

    # fixup VM properties
    vm <- vmss$properties$virtualMachineProfile

    vm$osProfile <- c(vm$osProfile,
        if(config$options$keylogin) vm_key_login else vm_pwd_login)

    vm$storageProfile$imageReference <- if(inherits(config$image, "image_custom"))
        list(id="[parameters('imageId')]")
    else list(
        publisher="[parameters('imagePublisher')]",
        offer="[parameters('imageOffer')]",
        sku="[parameters('imageSku')]",
        version="[parameters('imageVersion')]"
    )

    if(config$options$params$priority == "low")
        vm$evictionPolicy <- "[parameters('evictionPolicy')]"

    if(!is_empty(config$lb))
    {
        vm$
            networkProfile$
                networkInterfaceConfigurations[[1]]$
                    properties$
                        ipConfigurations[[1]]$
                            properties$
                                loadBalancerBackendAddressPools <- list(list(id="[variables('lbBackendId')]"))  # lol
    }

    vmss$properties$virtualMachineProfile <- vm

    # fixup nsg security rule priorities
    for(i in seq_along(config$nsg$properties$securityRules))
    {
        if(is_empty(config$nsg$properties$securityRules[[i]]$properties$priority))
            config$nsg$properties$securityRules[[i]]$properties$priority <- 1000 + 10 * i
    }

    ## fixup dependencies between resources
    # vnet depends on nsg
    # vmss depends on lb

    existing <- sapply(config[c("nsg", "vnet", "lb", "ip", "as")], existing_resource)
    unused <- sapply(config[c("nsg", "vnet", "lb", "ip", "as")], is.null)
    created <- !existing & !unused

    if(!created["nsg"])
        vnet$dependsOn <- NULL

    if(unused["nsg"])
        config$vnet$properties$subnets[[1]]$properties$networkSecurityGroup <- NULL

    resources <- mapply(utils::modifyList,
        list(nsg, vnet, lb, ip, as)[created],
        config[c("nsg", "vnet", "lb", "ip", "as")][created],
        SIMPLIFY=FALSE)

    resources <- c(resources, list(vmss))

    if(!is_empty(config$other))
        resources <- c(resources, config$other)

    resources
}
