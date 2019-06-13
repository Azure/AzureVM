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
    vars <- list(
        location="[resourceGroup().location]",
        vmId="[resourceId('Microsoft.Compute/virtualMachineScalesets', parameters('vmName'))]",
        vmRef="[concat('Microsoft.Compute/virtualMachineScalesets/', parameters('vmName'))]",
        vmPrefix="[concat(parameters('vmName'), '-instance')]"
    )

    for(res in c("nsg", "vnet", "lb", "ip", "as"))
        vars <- c(vars, add_template_variables(config[[res]], res))

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

    if(config$options$public)
    {
        vm$
            networkProfile$
                networkInterfaceConfigurations[[1]]$
                    properties$
                        ipConfigurations[[1]]$
                            properties$
                                publicIpAddressConfiguration <- list(
                                    name="pub1",
                                    properties=list(idleTimeoutInMinutes=15)
                                )
    }

    vmss$properties$virtualMachineProfile <- vm
    if(!is_empty(config$vmss_fields))
        vmss <- utils::modifyList(vmss, config$vmss_fields)

    resources <- config[c("nsg", "vnet", "lb", "ip", "as")]

    existing <- sapply(resources, existing_resource)
    unused <- sapply(resources, is.null)
    create <- !existing & !unused

    # cannot use lapply(*, build_resource_fields) because of lapply wart
    resources <- lapply(resources[create], function(x) build_resource_fields(x))

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
        resources <- c(resources, lapply(config$other, function(x) build_resource_fields(x)))

    unname(resources)
}
