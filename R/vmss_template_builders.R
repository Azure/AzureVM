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

    # if we don't have a load balancer, remove these vars
    if(is.null(config$lb))
        vars$lbFrontendName <- vars$lbFrontendId <- vars$lbBackendName <- vars$lbBackendId <- NULL

    # if we have an existing load balancer, extract the frontend and backend names
    if(is_resource(config$lb))
    {
        vars$lbFrontendName <- config$lb$properties$frontendIPConfigurations[[1]]$name
        vars$lbBackendName <- config$lb$properties$backendAddressPools[[1]]$name
    }

    # add any extra variables provided by the user    
    utils::modifyList(vars, config$variables)
}


add_template_resources.vmss_config <- function(config, ...)
{
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

    resources <- config[c("nsg", "vnet", "lb", "ip", "as")]

    existing <- sapply(resources, existing_resource)
    unused <- sapply(resources, is.null)
    create <- !existing & !unused

    resources <- lapply(resources[create], build_resource_fields)

    ## fixup dependencies between resources
    # vnet depends on nsg
    # vmss depends on vnet, lb

    if(create["vnet"])
    {
        if(!create["nsg"])
            resources$vnet$dependsOn <- NULL

        if(unused["nsg"])
            resources$vnet$properties$subnets[[1]]$properties$networkSecurityGroup <- NULL
    }

    vmss_depends <- character()
    if(create["lb"])
        vmss_depends <- c(vmss_depends, "[variables('lbRef')]")
    if(create["vnet"])
        vmss_depends <- c(vmss_depends, "[variables('vnetRef')]")
    vmss$dependsOn <- I(vmss_depends)

    resources <- c(resources, list(vmss))

    if(!is_empty(config$other))
        resources <- c(resources, lapply(config$other, build_resource_fields))

    unname(resources)
}
