#' VM configuration functions
#'
#' @param image For `vm_config`, the VM image to deploy. This should be an object of class `image_config`, created by the function of the same name.
#' @param keylogin Whether to use an SSH public key to login (TRUE) or a password (FALSE). Note that Windows does not support SSH key logins.
#' @param managed Whether to provide a managed system identity for the VM.
#' @param datadisks The data disks to attach to the VM. Specify this as either a vector of numeric disk sizes in GB, or a list of `datadisk_config` objects for more control over the specification.
#' @param nsg The network security group for the VM. Can be a call to `nsg_config` to create a new NSG; an AzureRMR resource object or resource ID to reuse an existing NSG; or NULL to not use an NSG (not recommended).
#' @param ip The public IP address for the VM. Can be a call to `ip_config` to create a new IP address; an AzureRMR resource object or resource ID to reuse an existing address resource; or NULL if the VM should not be accessible from outside its subnet.
#' @param vnet The virtual network for the VM. Can be a call to `vnet_config` to create a new virtual network, or an AzureRMR resource object or resource ID to reuse an existing virtual network. Note that by default, AzureVM will associate the NSG with the virtual network/subnet, not with the VM's network interface.
#' @param nic The network interface for the VM. Can be a call to `nic_config` to create a new interface, or an AzureRMR resource object or resource ID to reuse an existing interface.
#' @param other_resources An optional list of other resources to include in the deployment.
#' @param variables An optional named list of variables to add to the template.
#' @param ... For the specific VM configurations, other customisation arguments to be passed to `vm_config`. For `vm_config`, named arguments that will be folded into the VM resource definition in the template.
#'
#' @details
#' These functions are for specifying the details of a new virtual machine deployment: the VM image and related options, along with the Azure resources that the VM may need. These include the datadisks, network security group, public IP address (if the VM is to be accessible from outside its subnet), virtual network, and network interface. `vm_config` is the base configuration function, and the others call it to create VMs with specific operating systems and other image details.
#' - `ubuntu_dsvm`: Data Science Virtual Machine, based on Ubuntu 16.04
#' - `windows_dsvm`: Data Science Virtual Machine, based on Windows Server 2016
#' - `ubuntu_16.04`, `ubuntu_18.04`: Ubuntu LTS
#' - `windows_2016`, `windows_2019`: Windows Server Datacenter edition
#' - `rhel_7.6`, `rhel_8`: Red Hat Enterprise Linux
#' - `debian_9_backports`: Debian
#'
#' Each resource can be specified in a number of ways:
#' - To _create_ a new resource as part of the deployment, call the corresponding `*_config` function.
#' - To use an _existing_ resource, supply either an `AzureRMR::az_resource` object (recommended) or a string containing the resource ID.
#' - If the resource is not needed, specify it as NULL.
#' - For the `other_resources` argument, supply a list of resources, each of which should be a list of resource fields (name, type, properties, sku, etc).
#'
#' A VM configuration defines the following template variables by default, depending on its resources. If a particular resource is created, the corresponding `*Name`, `*Id` and `*Ref` variables will be available. If a resource is referred to but not created, the `*Name*` and `*Id` variables will be available. Other variables can be defined via the `variables` argument.
#'
#' \tabular{lll}{
#'   **Variable name** \tab **Contents** \tab **Description** \cr
#'  `location` \tab `[resourceGroup().location]` \tab Region to deploy resources \cr
#'  `vmId` \tab `[resourceId('Microsoft.Compute/virtualMachines', parameters('vmName'))]` \tab VM resource ID \cr
#'  `vmRef` \tab `[concat('Microsoft.Compute/virtualMachines/', parameters('vmName'))]` \tab VM template reference \cr
#'  `nsgName` \tab `[concat(parameters('vmName'), '-nsg')]` \tab Network security group resource name \cr
#'  `nsgId` \tab `[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]` \tab NSG resource ID \cr
#'  `nsgRef` \tab `[concat('Microsoft.Network/networkSecurityGroups/', variables('nsgName'))]` \tab NSG template reference \cr
#'  `ipName` \tab `[concat(parameters('vmName'), '-ip')]` \tab Public IP address resource name \cr
#'  `ipId` \tab `[resourceId('Microsoft.Network/publicIPAddresses', variables('ipName'))]` \tab IP resource ID \cr
#'  `ipRef` \tab `[concat('Microsoft.Network/publicIPAddresses/', variables('ipName'))]` \tab IP template reference \cr
#'  `vnetName` \tab `[concat(parameters('vmName'), '-vnet')]` \tab Virtual network resource name \cr
#'  `vnetId` \tab `[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]` \tab Vnet resource ID \cr
#'  `vnetRef` \tab `[concat('Microsoft.Network/virtualNetworks/', variables('vnetName'))]` \tab Vnet template reference \cr
#'  `subnet` \tab `subnet` \tab Subnet name. Only defined if a Vnet was created or supplied as an `az_resource` object. \cr
#'  `subnetId` \tab `[concat(variables('vnetId'), '/subnets/', variables('subnet'))]` \tab Subnet resource ID. Only defined if a Vnet was created or supplied as an `az_resource` object. \cr
#' `nicName` \tab `[concat(parameters('vmName'), '-nic')]` \tab Network interface resource name \cr
#' `nicId` \tab `[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]` \tab NIC resource ID \cr
#' `nicRef` \tab `[concat('Microsoft.Network/networkInterfaces/', variables('nicName'))]` \tab NIC template reference
#' }
#'
#' Thus, for example, if you are creating a VM named "myvm" along with all its associated resources, the NSG is named "myvm-nsg", the public IP address is "myvm-ip", the virtual network is "myvm-vnet", and the network interface is "myvm-nic".
#'
#' @return
#' An object of S3 class `vm_config`, that can be used by the `create_vm` method.
#'
#' @seealso
#' [image_config], [user_config], [datadisk_config] for options relating to the VM resource itself
#'
#' [nsg_config], [ip_config], [vnet_config], [nic_config] for other resource configs
#'
#' [build_template] for template builder methods
#'
#' [vmss_config] for configuring a virtual machine scaleset
#'
#' [create_vm]
#'
#' @examples
#'
#' # basic Linux (Ubuntu) and Windows configs
#' ubuntu_18.04()
#' windows_2019()
#'
#' # Windows DSVM with 500GB data disk, no public IP address
#' windows_dsvm(datadisks=500, ip=NULL)
#'
#' # RHEL VM exposing ports 80 (HTTP) and 443 (HTTPS)
#' rhel_8(nsg=nsg_config(nsg_rule_allow_http, nsg_rule_allow_https))
#'
#' # exposing no ports externally
#' rhel_8(nsg=nsg_config(list()))
#'
#' # deploying an extra resource: storage account
#' ubuntu_18.04(
#'     variables=list(storName="[concat(parameters('vmName'), 'stor')]"),
#'     other_resources=list(
#'         list(
#'             type="Microsoft.Storage/storageAccounts",
#'             name="[variables('storName')]",
#'             apiVersion="2018-07-01",
#'             location="[variables('location')]",
#'             properties=list(supportsHttpsTrafficOnly=TRUE),
#'             sku=list(name="Standard_LRS"),
#'             kind="Storage"
#'         )
#'     )
#' )
#'
#' ## custom VM configuration: Windows 10 Pro 1903 with data disks
#' ## this assumes you have a valid Win10 desktop license
#' user <- user_config("myname", password="Use-strong-passwords!")
#' image <- image_config(
#'      publisher="MicrosoftWindowsDesktop",
#'      offer="Windows-10",
#'      sku="19h1-pro"
#' )
#' datadisks <- list(
#'     datadisk_config(250, type="Premium_LRS"),
#'     datadisk_config(1000, type="Standard_LRS")
#' )
#' nsg <- nsg_config(
#'     list(nsg_rule_allow_rdp)
#' )
#' vm_config(
#'     image=image,
#'     keylogin=FALSE,
#'     datadisks=datadisks,
#'     nsg=nsg,
#'     properties=list(licenseType="Windows_Client")
#' )
#'
#'
#' \dontrun{
#'
#' # reusing existing resources: placing multiple VMs in one vnet/subnet
#' rg <- AzureRMR::get_azure_login()$
#'     get_subscription("sub_id")$
#'     get_resource_group("rgname")
#'
#' vnet <- rg$get_resource(type="Microsoft.Network/virtualNetworks", name="myvnet")
#'
#' # by default, the NSG is associated with the subnet, so we don't need a new NSG either
#' vmconfig1 <- ubuntu_18.04(vnet=vnet, nsg=NULL)
#' vmconfig2 <- debian_9_backports(vnet=vnet, nsg=NULL)
#' vmconfig3 <- windows_2019(vnet=vnet, nsg=NULL)
#'
#' }
#' @export
vm_config <- function(image, keylogin, managed=TRUE,
                      datadisks=numeric(0),
                      nsg=nsg_config(),
                      ip=ip_config(),
                      vnet=vnet_config(),
                      nic=nic_config(),
                      other_resources=list(),
                      variables=list(),
                      ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)

    stopifnot(inherits(image, "image_config"))
    stopifnot(is.list(datadisks) && all(sapply(datadisks, inherits, "datadisk_config")))

    ip <- vm_fixup_ip(ip)

    obj <- list(
        image=image,
        keylogin=keylogin,
        managed=managed,
        datadisks=datadisks,
        nsg=nsg,
        ip=ip,
        vnet=vnet,
        nic=nic,
        other=other_resources,
        variables=variables,
        vm_fields=list(...)
    )
    structure(obj, class="vm_config")
}


vm_fixup_ip <- function(ip)
{
    # don't try to fix IP if not created here
    if(is.null(ip) || !inherits(ip, "ip_config"))
        return(ip)

    # default for a regular VM: sku=basic, allocation=dynamic
    if(is.null(ip$type))
        ip$type <- "basic"
    if(is.null(ip$dynamic))
        ip$dynamic <- tolower(ip$type) == "basic"

    # check consistency
    if(tolower(ip$type) == "standard" && ip$dynamic)
        stop("Standard IP address type does not support dynamic allocation", call.=FALSE)

    ip
}


#' @rdname vm_config
#' @export
ubuntu_dsvm <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                        ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    disk0 <- datadisk_config(NULL, NULL, "fromImage", "Premium_LRS")
    vm_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"),
              keylogin=keylogin, managed=managed, datadisks=c(list(disk0), datadisks), nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
windows_dsvm <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"),
              keylogin=FALSE, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
ubuntu_16.04 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Canonical", "UbuntuServer", "16.04-LTS"),
              keylogin=keylogin, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
ubuntu_18.04 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
              keylogin=keylogin, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
windows_2016 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"),
              keylogin=FALSE, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
windows_2019 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter"),
              keylogin=FALSE, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
rhel_7.6 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                       nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "7-RAW"),
              keylogin=keylogin, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
rhel_8 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                     nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "8"),
              keylogin=keylogin, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
debian_9_backports <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                              nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Credativ", "Debian", "9-backports"),
              keylogin=keylogin, managed=managed, datadisks=datadisks, nsg=nsg, ...)
}
