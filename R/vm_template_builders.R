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

    if(length(config$datadisks) > 0)
        add_param(dataDisks="array", dataDiskResources="array")

    params
}


add_template_variables.vm_config <- function(config, ...)
{
    vars <- list(
        location="[resourceGroup().location]",
        vmId="[resourceId('Microsoft.Compute/virtualMachines', parameters('vmName'))]",
        vmRef="[concat('Microsoft.Compute/virtualMachines/', parameters('vmName'))]"
    )

    for(res in c("nsg", "ip", "vnet", "nic"))
        vars <- c(vars, add_template_variables(config[[res]], res))

    # add any extra variables provided by the user
    utils::modifyList(vars, config$variables)
}


add_template_resources.vm_config <- function(config, ...)
{
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

    vm$properties$storageProfile$osDisk$managedDisk$storageAccountType <- config$os_disk_type

    vm$properties$osProfile <- c(vm$properties$osProfile,
        if(config$keylogin) vm_key_login else vm_pwd_login)

    if(inherits(config$image, "image_custom"))
        vm$properties$storageProfile$imageReference <- list(id="[parameters('imageId')]")

    if(!is_empty(config$vm_fields))
        vm <- utils::modifyList(vm, config$vm_fields)

    resources <- config[c("nsg", "ip", "vnet", "nic")]

    existing <- sapply(resources, existing_resource)
    unused <- sapply(resources, is.null)
    create <- !existing & !unused

    # cannot use lapply(*, build_resource_fields) because of lapply wart
    resources <- lapply(resources[create], function(x) build_resource_fields(x))

    ## fixup dependencies between resources
    # vnet depends on nsg
    # nic depends on ip, vnet (possibly nsg)
    # vm depends on nic (but nic should always be created)

    if(create["vnet"])
    {
        if(!create["nsg"])
        resources$vnet$dependsOn <- NULL

        if(unused["nsg"])
        resources$vnet$properties$subnets[[1]]$properties$networkSecurityGroup <- NULL
    }

    if(create["nic"])
    {
        nic_created_depends <- create[c("ip", "vnet")]
        resources$nic$dependsOn <- resources$nic$dependsOn[nic_created_depends]
        if(unused["ip"])
            resources$nic$properties$ipConfigurations[[1]]$properties$publicIPAddress <- NULL
    }
    else vm$dependsOn <- NULL

    if(n_disk_resources > 0)
        resources <- c(resources, list(disk_default))

    resources <- c(resources, list(vm))

    if(!is_empty(config$other))
        resources <- c(resources, lapply(config$other, function(x) build_resource_fields(x)))

    unname(resources)
}


# check if we are referring to an existing resource or creating a new one
existing_resource <- function(object)
{
    # can be a resource ID string or AzureRMR::az_resource object
    is.character(object) || is_resource(object)
}


