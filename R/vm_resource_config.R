#' Resource configuration functions for a virtual machine deployment
#'
#' @param username For `user_config`, the name for the admin user account.
#' @param sshkey For `user_config`, an SSH public key. Can be a string, or the name of the public key file.
#' @param password For `user_config`, the admin password. Supply either `sshkey` or `password`, but not both; also, note that Windows does not support SSH logins.
#' @param size For `datadisk_config`, the size of the data disk in GB. St this to NULL for a disk that will be created from an image.
#' @param name The name of a resource: for `datadisk_config`, the disk name; for `nsg_rule_config`, the security rule name; for `subnet_config`, the name of a subnet; for `nic_ip_config`, the name of a network IP configuration. Duplicate names will automatically be disambiguated prior to VM deployment.
#' @param create For `datadisk_config`, the creation method. Can be "empty" (the default) to create a blank disk, or "fromImage" to use an image.
#' @param type For `datadisk_config`, the disk type (SKU). Can be "Standard_LRS", "StandardSSD_LRS" (the default), "Premium_LRS" or "UltraSSD_LRS". Of these, "Standard_LRS" uses hard disks and the others use SSDs as the underlying hardware.
#' @param write_accelerator For `datadisk_config`, whether the disk should have write acceleration enabled.
#' @param publisher,offer,sku,version For `image_config`, the details for a marketplace image.
#' @param id For `image_config`, the resource ID for a disk to use as a custom image.
#' @param rules for `nsg_config`, a list of security rule objects, each obtained via a call to `nsg_rule_config`.
#' @param dest_port,dest_addr,dest_asgs For `nsg_rule_config`, the destination port, address range, and application security groups for a rule.
#' @param source_port,source_addr,source_asgs For `nsg_rule_config`, the source port, address range, and application security groups for a rule.
#' @param access For `nsg_rule_config`, the action to take: "allow" or "deny".
#' @param direction For `nsg_rule_config`, the direction of traffic: "inbound" or "outbound".
#' @param protocol For `nsg_rule_config`, the network protocol: either "TCP" or "UDP".
#' @param priority For `nsg_rule_config`, the rule priority. If NULL, this will be set automatically by AzureVM.
#' @param allocation For `ip_config`, the IP address allocation method: either "dynamic" or "static". In the latter case, the VM's public IP address will persist between shutdowns.
#' @param ipv6 For `ip_config`, whether to use IPv6 addresses.
#' @param domain_name For `ip_config`, the domain name label to associate with the address. Defaults to the VM's machine name.
#' @param address_space For `vnet_config`, the address range accessible by the virtual network, expressed in CIDR block format.
#' @param subnets For `vnet_config`, a list of subnet objects, each obtained via a call to `subnet_config`.
#' @param addresses For `subnet_config`, the address ranges spanned by this subnet. Must be a subset of the address space available to the parent virtual network.
#' @param nsg The network security group associated with this subnet. Defaults to the NSG created as part of this VM deployment.
#' @param nic_ip For `nic_config`, a list of IP configuration objects, each obtained via a call to `nic_ip_config`.
#' @param private_alloc For `nic_ip_config`, the allocation method for a private IP address. Can be "dynamic" or "static".
#' @param subnet For `nic_ip_config`, the subnet to associate with this private IP address.
#' @param public_address For `nic_ip_config`, the public IP address. Defaults to the public IP address created or used as part of this VM deployment. Ignored if the deployment does not include a public address.
#' @param ... Other named arguments that will be treated as resource fields.
#'
#' @rdname resource_config
#' @export
user_config <- function(username, sshkey=NULL, password=NULL)
{
    pwd <- is.character(password)
    key <- is.character(sshkey)
    if(!pwd && !key)
        stop("Must supply either a login password or SSH key", call.=FALSE)
    if(pwd && key)
        stop("Supply either a login password or SSH key, but not both", call.=FALSE)

    if(key && file.exists(sshkey))
        sshkey <- readLines(sshkey)

    structure(list(user=username, key=sshkey, pwd=password), class="user_config")
}


#' @rdname resource_config
#' @export
datadisk_config <- function(size, name="datadisk", create="empty", type="StandardSSD_LRS", write_accelerator=FALSE)
{
    vm_caching <- if(type == "Premium_LRS") "ReadOnly" else "None"
    vm_create <- if(create == "empty") "attach" else "fromImage"
    vm_storage <- if(create == "empty") NULL else type

    vm_spec <- list(
        createOption=vm_create,
        caching=vm_caching,
        writeAcceleratorEnabled=write_accelerator,
        storageAccountType=vm_storage,
        diskSizeGB=NULL,
        id=NULL,
        name=name
    )

    res_spec <- if(!is.null(size))
        list(
            diskSizeGB=size,
            sku=type,
            creationData=list(createOption=create),
            name=name
        )
    else NULL

    structure(list(res_spec=res_spec, vm_spec=vm_spec), class="datadisk_config")
}


#' @rdname resource_config
#' @export
image_config <- function(publisher=NULL, offer=NULL, sku=NULL, version="latest", id=NULL)
{
    if(!is.null(publisher) && !is.null(offer) && !is.null(sku))
    {
        structure(list(publisher=publisher, offer=offer, sku=sku, version=version),
                  class=c("image_marketplace", "image_config"))
    }
    else if(!is.null(id))
    {
        structure(list(id=id),
                  class=c("image_custom", "image_config"))
    }
    else stop("Invalid image configuration", call.=FALSE)
}


#' @rdname resource_config
#' @export
nsg_config <- function(rules=list(), ...)
{
    stopifnot(is.list(rules))
    props <- list(securityRules=lapply(rules, unclass), ...)
    structure(list(properties=props), class="nsg_config")
}


#' @rdname resource_config
#' @export
nsg_rule_config <- function(name, dest_port="*", dest_addr="*", dest_asgs=NULL,
                            source_port="*", source_addr="*", source_asgs=NULL,
                            access="allow", direction="inbound",
                            protocol="Tcp", priority=NULL)
{
    if(is_empty(dest_asgs))
        dest_asgs <- logical(0)
    if(is_empty(source_asgs))
        source_asgs <- logical(0)

    properties <- list(
        protocol=protocol,
        access=access,
        direction=direction,
        sourceApplicationSecurityGroups=source_asgs,
        destinationApplicationSecurityGroups=dest_asgs,
        sourceAddressPrefix=source_addr,
        sourcePortRange=as.character(source_port),
        destinationAddressPrefix=dest_addr,
        destinationPortRange=as.character(dest_port)
    )

    if(!is_empty(priority))
        properties$priority <- priority

    structure(list(name=name, properties=properties), class="nsg_rule_config")
}


#' @rdname resource_config
#' @export
ip_config <- function(allocation="dynamic", ipv6=FALSE, domain_name="[parameters('vmName')]", ...)
{
    version <- if(ipv6) "IPv6" else "IPv4"
    props <- list(publicIPAllocationMethod=allocation, publicIPAddressVersion=version, ...)
    if(!is.null(domain_name))
        props$dnsSettings$domainNameLabel <- domain_name

    structure(list(properties=props), class="ip_config")
}


#' @rdname resource_config
#' @export
vnet_config <- function(address_space="10.0.0.0/16", subnets=list(subnet_config()), ...)
{
    # attempt to fixup address blocks so they are consistent (should really use iptools)
    ab_regex <- "^([0-9]+\\.[0-9]+).*$"
    ab_block <- sub(ab_regex, "\\1", address_space)
    fixaddr <- function(addr)
    {
        if(sub(ab_regex, "\\1", addr) == ab_block)
            sub("^[0-9]+\\.[0-9]+", ab_block, addr)
        else addr
    }
    subnets <- lapply(subnets, function(sn)
    {
        if(!inherits(sn, "subnet_config"))
            stop("Not a subnet object", call.=FALSE)

        if(!is_empty(sn$properties$addressPrefix))
            sn$properties$addressPrefix <- fixaddr(sn$properties$addressPrefix)
        if(!is_empty(sn$properties$addressPrefixes))
            sn$properties$addressPrefixes <- sapply(sn$properties$addressPrefixes, fixaddr)

        unclass(sn)
    })

    # unique-ify subnet names
    if(length(subnets) > 1)
    {
        sn_names <- make.unique(sapply(subnets, `[[`, "name"))
        sn_names[1] <- paste0(sn_names[1], "0")
        for(i in seq_along(subnets))
            subnets[[i]]$name <- sn_names[i]
    }

    props <- list(
        addressSpace=list(addressPrefixes=I(address_space)),
        subnets=subnets,
        ...
    )
    structure(list(properties=props), class="vnet_config")
}


#' @rdname resource_config
#' @export
subnet_config <- function(name="subnet", addresses="10.0.0.0/24", nsg="[variables('nsgId')]", ...)
{
    properties <- if(length(addresses) < 2)
        list(addressPrefix=addresses, ...)
    else list(addressPrefixes=addresses, ...)

    # check if supplied a network security group resource ID or object
    if(is.character(nsg))
        properties$networkSecurityGroup$id <- nsg
    else if(is_resource(nsg) && tolower(nsg$type) == "microsoft.network/networksecuritygroups")
        properties$networkSecurityGroup$id <- nsg$id
    else if(!is.null(nsg))
        warning("Invalid network security group", call.=FALSE)

    subnet <- list(name=name, properties=properties)
    structure(subnet, class="subnet_config")
}


#' @rdname resource_config
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

    props <- list(ipConfigurations=lapply(nic_ip, unclass), ...)
    structure(list(properties=props), class="nic_config")
}


#' @rdname resource_config
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


#' Network security rules
#'
#' @section Usage:
#' ```
#' nsg_rule_allow_http
#' nsg_rule_allow_https
#' nsg_rule_allow_jupyter
#' nsg_rule_allow_rdp
#' nsg_rule_allow_rstudio
#' nsg_rule_allow_ssh
#' ```
#' @section Details:
#' These are the default network security rules provided by AzureVM. They are setup to allow specific ports through the Azure firewall. You should only allow the ports that you need.
#' - HTTP: TCP port 80
#' - HTTPS: TCP port 443
#' - JupyterHub: TCP port 8000
#' - RDP: TCP port 3389
#' - RStudio Server: TCP port 8787
#' - SSH: TCP port 22
#' @docType data
#' @rdname nsg_rule
#' @export
nsg_rule_allow_ssh <- nsg_rule_config("Allow-ssh", 22)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_http <- nsg_rule_config("Allow-http", 80)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_https <- nsg_rule_config("Allow-https", 443)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_rdp <- nsg_rule_config("Allow-rdp", 3389)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_jupyter <- nsg_rule_config("Allow-jupyter", 8000)

#' @rdname nsg_rule
#' @export
nsg_rule_allow_rstudio <- nsg_rule_config("Allow-rstudio", 8787)

