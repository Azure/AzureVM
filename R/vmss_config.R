#' Virtual machine scaleset configuration functions
#'
#' @param image For `vmss_config`, the VM image to deploy. This should be an object of class `image_config`, created by the function of the same name.
#' @param options Scaleset options, as obtained via a call to `scaleset_options`.
#' @param datadisks The data disks to attach to the VM. Specify this as either a vector of numeric disk sizes in GB, or a list of `datadisk_config` objects for more control over the specification.
#' @param dsvm_disk_type The Ubuntu DSVM image comes with one additional datadisk that holds some installed tools. This argument sets what type of disk is used. Change this to "StandardSSD_LRS" or "Standard_LRS" if the VM size doesn't support premium storage.
#' @param nsg The network security group for the scaleset. Can be a call to `nsg_config` to create a new NSG; an AzureRMR resource object or resource ID to reuse an existing NSG; or NULL to not use an NSG (not recommended).
#' @param vnet The virtual network for the scaleset. Can be a call to `vnet_config` to create a new virtual network, or an AzureRMR resource object or resource ID to reuse an existing virtual network. Note that by default, AzureVM will associate the NSG with the virtual network/subnet, not with the VM's network interface.
#' @param load_balancer The load balancer for the scaleset. Can be a call to `lb_config` to create a new load balancer;  an AzureRMR resource object or resource ID to reuse an existing load balancer; or NULL if load balancing is not required.
#' @param load_balancer_address The public IP address for the load balancer. Can be a call to `ip_config` to create a new IP address, or an AzureRMR resource object or resource ID to reuse an existing address resource. Ignored if `load_balancer` is NULL.
#' @param autoscaler The autoscaler for the scaleset. Can be a call to `autoscaler_config` to create a new autoscaler; an AzureRMR resource object or resource ID to reuse an existing autoscaler; or NULL if autoscaling is not required.
#' @param other_resources An optional list of other resources to include in the deployment.
#' @param variables An optional named list of variables to add to the template.
#' @param ... For the specific VM configurations, other customisation arguments to be passed to `vm_config`. For `vmss_config`, named arguments that will be folded into the scaleset resource definition in the template.
#'
#' @details
#' These functions are for specifying the details of a new virtual machine scaleset deployment: the base VM image and related options, along with the Azure resources that the scaleset may need. These include the network security group, virtual network, load balancer and associated public IP address, and autoscaler.
#'
#' Each resource can be specified in a number of ways:
#' - To _create_ a new resource as part of the deployment, call the corresponding `*_config` function.
#' - To use an _existing_ resource, supply either an `AzureRMR::az_resource` object (recommended) or a string containing the resource ID.
#' - If the resource is not needed, specify it as NULL.
#' - For the `other_resources` argument, supply a list of resources, each of which should be a list of resource fields (name, type, properties, sku, etc).
#'
#' The `vmss_config` function is the base configuration function, and the others call it to create VM scalesets with specific operating systems and other image details.
#' - `ubuntu_dsvm_ss`: Data Science Virtual Machine, based on Ubuntu 16.04
#' - `windows_dsvm_ss`: Data Science Virtual Machine, based on Windows Server 2016
#' - `ubuntu_16.04_ss`, `ubuntu_18.04`: Ubuntu LTS
#' - `windows_2016_ss`, `windows_2019`: Windows Server Datacenter edition
#' - `rhel_7.6_ss`, `rhel_8_ss`: Red Hat Enterprise Linux
#' - `centos_7.5_ss`, `centos_7.6_ss`: CentOS
#' - `debian_8_backports_ss`, `debian_9_backports_ss`: Debian with backports
#'
#' A VM scaleset configuration defines the following template variables by default, depending on its resources. If a particular resource is created, the corresponding `*Name`, `*Id` and `*Ref` variables will be available. If a resource is referred to but not created, the `*Name*` and `*Id` variables will be available. Other variables can be defined via the `variables` argument.
#'
#' \tabular{lll}{
#'   **Variable name** \tab **Contents** \tab **Description** \cr
#'  `location` \tab `[resourceGroup().location]` \tab Region to deploy resources \cr
#'  `vmId` \tab `[resourceId('Microsoft.Compute/virtualMachines', parameters('vmName'))]` \tab VM scaleset resource ID \cr
#'  `vmRef` \tab `[concat('Microsoft.Compute/virtualMachines/', parameters('vmName'))]` \tab Scaleset template reference \cr
#'  `nsgName` \tab `[concat(parameters('vmName'), '-nsg')]` \tab Network security group resource name \cr
#'  `nsgId` \tab `[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]` \tab NSG resource ID \cr
#'  `nsgRef` \tab `[concat('Microsoft.Network/networkSecurityGroups/', variables('nsgName'))]` \tab NSG template reference \cr
#'  `vnetName` \tab `[concat(parameters('vmName'), '-vnet')]` \tab Virtual network resource name \cr
#'  `vnetId` \tab `[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]` \tab Vnet resource ID \cr
#'  `vnetRef` \tab `[concat('Microsoft.Network/virtualNetworks/', variables('vnetName'))]` \tab Vnet template reference \cr
#'  `subnet` \tab `subnet` \tab Subnet name. Only defined if a Vnet was created or supplied as an `az_resource` object. \cr
#'  `subnetId` \tab `[concat(variables('vnetId'), '/subnets/', variables('subnet'))]` \tab Subnet resource ID. Only defined if a Vnet was created or supplied as an `az_resource` object. \cr
#'  `lbName` \tab `[concat(parameters('vmName'), '-lb')]` \tab Load balancer resource name \cr
#'  `lbId` \tab `[resourceId('Microsoft.Network/loadBalancers', variables('lbName'))]` \tab Load balancer resource ID \cr
#'  `lbRef` \tab `[concat('Microsoft.Network/loadBalancers/', variables('lbName'))]` \tab Load balancer template reference \cr
#'  `lbFrontendName` \tab `frontend` \tab Load balancer frontend IP configuration name. Only defined if a load balancer was created or supplied as an `az_resource` object. \cr
#'  `lbBackendName` \tab `backend` \tab Load balancer backend address pool name. Only defined if a load balancer was created or supplied as an `az_resource` object. \cr
#'  `lbFrontendId` \tab `[concat(variables('lbId'), '/frontendIPConfigurations/', variables('lbFrontendName'))]` \tab Load balancer frontend resource ID. Only defined if a load balancer was created or supplied as an `az_resource` object. \cr
#'  `lbBackendId` \tab `[concat(variables('lbId'), '/backendAddressPools/', variables('lbBackendName'))]` \tab Load balancer backend resource ID. Only defined if a load balancer was created or supplied as an `az_resource` object. \cr
#'  `ipName` \tab `[concat(parameters('vmName'), '-ip')]` \tab Public IP address resource name \cr
#'  `ipId` \tab `[resourceId('Microsoft.Network/publicIPAddresses', variables('ipName'))]` \tab IP resource ID \cr
#'  `ipRef` \tab `[concat('Microsoft.Network/publicIPAddresses/', variables('ipName'))]` \tab IP template reference \cr
#'  `asName` \tab `[concat(parameters('vmName'), '-as')]` \tab Autoscaler resource name \cr
#' `asId` \tab `[resourceId('Microsoft.Insights/autoscaleSettings', variables('asName'))]` \tab Autoscaler resource ID \cr
#' `asRef` \tab `[concat('Microsoft.Insights/autoscaleSettings/', variables('asName'))]` \tab Autoscaler template reference \cr
#' `asMaxCapacity` \tab `[mul(int(parameters('instanceCount')), 10)]` \tab Maximum capacity for the autoscaler. Only defined if an autoscaler was created. \cr
#' `asScaleValue` \tab `[max(div(int(parameters('instanceCount')), 5), 1)]` \tab Default capacity for the autoscaler. Only defined if an autoscaler was created.
#' }
#'
#' Thus, for example, if you are creating a VM scaleset named "myvmss" along with all its associated resources, the NSG is named "myvmss-nsg", the virtual network is "myvmss-vnet", the load balancer is "myvmss-lb", the public IP address is "myvmss-ip", and the autoscaler is "myvm-as".

#'
#' @return
#' An object of S3 class `vmss_config`, that can be used by the `create_vm_scaleset` method.
#'
#' @seealso
#' [scaleset_options] for options relating to the scaleset resource itself
#'
#' [nsg_config], [ip_config], [vnet_config], [lb_config], [autoscaler_config] for other resource configs
#'
#' [build_template] for template builder methods
#'
#' [vm_config] for configuring an individual virtual machine
#'
#' [create_vm_scaleset]
#'
#' @examples
#'
#' # basic Linux (Ubuntu) and Windows configs
#' ubuntu_18.04_ss()
#' windows_2019_ss()
#'
#' # Windows DSVM scaleset, no load balancer and autoscaler
#' windows_dsvm_ss(load_balancer=NULL, autoscaler=NULL)
#'
#' # RHEL VM exposing ports 80 (HTTP) and 443 (HTTPS)
#' rhel_8_ss(nsg=nsg_config(nsg_rule_allow_http, nsg_rule_allow_https))
#'
#' # exposing no ports externally
#' rhel_8_ss(nsg=nsg_config(list()))
#'
#' # low-priority VMs, large scaleset (>100 instances allowed), no managed identity
#' rhel_8_ss(options=scaleset_options(low_priority=TRUE, large_scaleset=TRUE, managed_identity=FALSE))
#'
#'
#' \dontrun{
#'
#' # reusing existing resources: placing a scaleset in an existing vnet/subnet
#' # we don't need a new network security group either
#' vnet <- AzureRMR::get_azure_login()$
#'     get_subscription("sub_id")$
#'     get_resource_group("rgname")$
#'     get_resource(type="Microsoft.Network/virtualNetworks", name="myvnet")
#'
#' ubuntu_18.04_ss(vnet=vnet, nsg=NULL)
#'
#' }
#' @export
vmss_config <- function(image, options=scaleset_options(),
                        datadisks=numeric(0),
                        nsg=nsg_config(),
                        vnet=vnet_config(),
                        load_balancer=lb_config(),
                        load_balancer_address=ip_config(),
                        autoscaler=autoscaler_config(),
                        other_resources=list(),
                        variables=list(),
                        ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)

    stopifnot(inherits(image, "image_config"))
    stopifnot(inherits(options, "scaleset_options"))
    stopifnot(is.list(datadisks) && all(sapply(datadisks, inherits, "datadisk_config")))

    # make IP sku, balancer sku and scaleset size consistent with each other
    load_balancer <- vmss_fixup_lb(options, load_balancer)
    ip <- vmss_fixup_ip(options, load_balancer, load_balancer_address)

    obj <- list(
        image=image,
        options=options,
        datadisks=datadisks,
        nsg=nsg,
        vnet=vnet,
        lb=load_balancer,
        ip=ip,
        as=autoscaler,
        other=other_resources,
        variables=variables,
        vmss_fields=list(...)
    )
    structure(obj, class="vmss_config")
}


vmss_fixup_lb <- function(options, lb)
{
    # don't try to fix load balancer if not created here
    if(is.null(lb) || !inherits(lb, "lb_config"))
        return(lb)

    # for a large scaleset, must set sku=standard
    if(!options$params$singlePlacementGroup)
    {
        if(is.null(lb$type))
            lb$type <- "standard"
        else if(tolower(lb$type) != "standard")
            stop("Load balancer type must be 'standard' for large scalesets", call.=FALSE)
    }
    else
    {
        if(is.null(lb$type))
            lb$type <- "basic"
    }

    lb
}


vmss_fixup_ip <- function(options, lb, ip)
{
    # IP address only required if load balancer is present
    if(is.null(lb))
        return(NULL)

    # don't try to fix IP if load balancer was provided as a resource id
    if(is.character(lb))
        return(ip)

    # don't try to fix IP if not created here
    if(is.null(ip) || !inherits(ip, "ip_config"))
        return(ip)

    lb_type <- if(is_resource(lb))
        lb$sku$name
    else lb$type

    # for a large scaleset, must set sku=standard, allocation=static
    if(!options$params$singlePlacementGroup)
    {
        if(is.null(ip$type))
            ip$type <- "standard"
        else if(tolower(ip$type) != "standard")
            stop("Load balancer IP address type must be 'standard' for large scalesets", call.=FALSE)

        if(is.null(ip$dynamic))
            ip$dynamic <- FALSE
        else if(ip$dynamic)
            stop("Load balancer dynamic IP address not supported for large scalesets", call.=FALSE)
    }
    else
    {
        # defaults for small scaleset: sku=load balancer sku, allocation=dynamic
        if(is.null(ip$type))
            ip$type <- lb_type
        if(is.null(ip$dynamic))
            ip$dynamic <- tolower(ip$type) == "basic"
    }

    # check consistency
    if(tolower(ip$type) == "standard" && ip$dynamic)
        stop("Standard IP address type does not support dynamic allocation", call.=FALSE)

    ip
}


#' @rdname vmss_config
#' @export
ubuntu_dsvm_ss <- function(datadisks=numeric(0),
                           dsvm_disk_type=c("Premium_LRS", "StandardSSD_LRS", "Standard_LRS"),
                           nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                           load_balancer=lb_config(rules=list(lb_rule_ssh, lb_rule_jupyter, lb_rule_rstudio),
                                                   probes=list(lb_probe_ssh, lb_probe_jupyter, lb_probe_rstudio)),
                           ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    dsvm_disk_type <- match.arg(dsvm_disk_type)
    disk0 <- datadisk_config(NULL, NULL, "fromImage", dsvm_disk_type)
    vmss_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"),
                datadisks=c(list(disk0), datadisks), nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_dsvm_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                   probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    options$keylogin <- FALSE
    vmss_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"),
                options=options, datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
ubuntu_16.04_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_ssh)),
                            load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                    probes=list(lb_probe_ssh)),
                            ...)
{
    vmss_config(image_config("Canonical", "UbuntuServer", "16.04-LTS"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
ubuntu_18.04_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_ssh)),
                            load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                    probes=list(lb_probe_ssh)),
                            ...)
{
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_2016_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                    probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    options$keylogin <- FALSE
    vmss_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"),
                options=options, datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_2019_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                    probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    options$keylogin <- FALSE
    vmss_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter"),
                options=options, datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
rhel_7.6_ss <- function(datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)),
                        load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                probes=list(lb_probe_ssh)),
                        ...)
{
    vmss_config(image_config("RedHat", "RHEL", "7-RAW"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
rhel_8_ss <- function(datadisks=numeric(0),
                      nsg=nsg_config(list(nsg_rule_allow_ssh)),
                      load_balancer=lb_config(rules=list(lb_rule_ssh),
                                              probes=list(lb_probe_ssh)),
                      ...)
{
    vmss_config(image_config("RedHat", "RHEL", "8"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
centos_7.5_ss <- function(datadisks=numeric(0),
                          nsg=nsg_config(list(nsg_rule_allow_ssh)),
                          load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                  probes=list(lb_probe_ssh)),
                          ...)
{
    vmss_config(image_config("OpenLogic", "CentOS", "7.5"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
centos_7.6_ss <- function(datadisks=numeric(0),
                          nsg=nsg_config(list(nsg_rule_allow_ssh)),
                          load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                  probes=list(lb_probe_ssh)),
                          ...)
{
    vmss_config(image_config("OpenLogic", "CentOS", "7.6"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
debian_8_backports_ss <- function(datadisks=numeric(0),
                                  nsg=nsg_config(list(nsg_rule_allow_ssh)),
                                  load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                          probes=list(lb_probe_ssh)),
                                  ...)
{
    vmss_config(image_config("Credativ", "Debian", "8-backports"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
debian_9_backports_ss <- function(datadisks=numeric(0),
                                  nsg=nsg_config(list(nsg_rule_allow_ssh)),
                                  load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                          probes=list(lb_probe_ssh)),
                                  ...)
{
    vmss_config(image_config("Credativ", "Debian", "9-backports"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}


#' Virtual machine scaleset options
#'
#' @param keylogin Whether to use an SSH public key to login (TRUE) or a password (FALSE). Note that Windows does not support SSH key logins.
#' @param managed_identity Whether to provide a managed system identity for the VM.
#' @param public Whether the instances (nodes) of the scaleset should be visible from the public internet.
#' @param priority The priority of the VM scaleset, either `regular` or `spot`. Spot VMs are considerably cheaper but subject to eviction if other, higher-priority workloads require compute resources.
#' @param delete_on_evict If spot-priority VMs are being used, whether evicting (shutting down) a VM should delete it, as opposed to just deallocating it.
#' @param network_accel Whether to enable accelerated networking. This option is only available for certain VM sizes.
#' @param large_scaleset Whether to enable scaleset sizes > 100 instances.
#' @param overprovision Whether to overprovision the scaleset on creation.
#' @param upgrade_policy A list, giving the VM upgrade policy for the scaleset.
#' @param os_disk_type The type of primary disk for the VM. Change this to "StandardSSD_LRS" or "Standard_LRS" if the VM size doesn't support premium storage.
#'
#' @export
scaleset_options <- function(keylogin=TRUE, managed_identity=TRUE, public=FALSE,
                             priority=c("regular", "spot"), delete_on_evict=FALSE,
                             network_accel=FALSE, large_scaleset=FALSE,
                             overprovision=TRUE, upgrade_policy=list(mode="manual"),
                             os_disk_type=c("Premium_LRS", "StandardSSD_LRS", "Standard_LRS"))
{
    params <- list(
        priority=match.arg(priority),
        evictionPolicy=if(delete_on_evict) "delete" else "deallocate",
        enableAcceleratedNetworking=network_accel,
        singlePlacementGroup=!large_scaleset,
        overprovision=overprovision,
        upgradePolicy=upgrade_policy
    )

    os_disk_type <- match.arg(os_disk_type)
    out <- list(keylogin=keylogin, managed_identity=managed_identity, public=public, os_disk_type=os_disk_type, params=params)
    structure(out, class="scaleset_options")
}

