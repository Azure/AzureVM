#' Network interface configuration
#'
#' @param nic_ip For `nic_config`, a list of IP configuration objects, each obtained via a call to `nic_ip_config`.
#' @param name For `nic_ip_config`, the name of the IP configuration.
#' @param private_alloc For `nic_ip_config`, the allocation method for a private IP address. Can be "dynamic" or "static".
#' @param subnet For `nic_ip_config`, the subnet to associate with this private IP address.
#' @param public_address For `nic_ip_config`, the public IP address. Defaults to the public IP address created or used as part of this VM deployment. Ignored if the deployment does not include a public address.
#' @param ... Other named arguments that will be treated as resource properties.
#'
#' @seealso
#' [create_vm], [vm_config]
#' @export
nic_config <- function(nic_ip=list(nic_ip_config()), ...)
{
    # unique-ify ip config names
    if(length(nic_ip) > 1)
    {
        ip_names <- make.unique(sapply(nic_ip, `[[`, "name"))
        ip_names[1] <- paste0(ip_names[1], "0")
        for(i in seq_along(nic_ip))
            nic_ip[[i]]$name <- ip_names[i]
    }

    props <- list(ipConfigurations=nic_ip, ...)
    structure(list(properties=props), class="nic_config")
}


build_resource_fields.nic_config <- function(config)
{
    config$properties$ipConfigurations <- lapply(config$properties$ipConfigurations, unclass)
    utils::modifyList(nic_default, config)
}


add_template_variables.nic_config <- function(config, ...)
{
    name <- "[concat(parameters('vmName'), '-nic')]"
    id <- "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"
    ref <- "[concat('Microsoft.Network/networkInterfaces/', variables('nicName'))]"
    list(nicName=name, nicId=id, nicRef=ref)
}


#' @rdname nic_config
#' @export
nic_ip_config <- function(name="ipconfig", private_alloc="dynamic", subnet="[variables('subnetId')]",
                          public_address="[variables('ipId')]", ...)
{
    props <- list(
        privateIPAllocationMethod=private_alloc,
        subnet=list(id=subnet),
        publicIPAddress=list(id=public_address),
        ...
    )
    structure(list(name=name, properties=props), class="nic_ip_config")
}


