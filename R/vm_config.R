#' VM configuration functions
#'
#' @param image For `vm_config`, the VM image to deploy. This should be an object of class `image_config`, created by the function of the same name.
#' @param keylogin Boolean: whether to use an SSH public key to login (TRUE) or a password (FALSE). Note that Windows does not support SSH key logins.
#' @param managed Whether to provide a managed system identity for the VM.
#' @param datadisks The data disks to attach to the VM. Specify this as either a vector of numeric disk sizes in GB, or a list of `datadisk_config` objects for more control over the specification.
#' @param nsg The network security group for the VM. Can be a call to `nsg_config` to create a new NSG; an AzureRMR resource object or resource ID to reuse an existing NSG; or NULL to not use an NSG (not recommended).
#' @param ip The public IP address for the VM. Can be a call to `ip_config` to create a new IP address; an AzureRMR resource object or resource ID to reuse an existing address resource; or NULL if the VM should not be accessible from outside its subnet.
#' @param vnet The virtual network for the VM. Can be a call to `vnet_config` to create a new virtual network, or an AzureRMR resource object or resource ID to reuse an existing virtual network.
#' @param nic The network interface for the VM. Can be a call to `nic_config` to create a new interface, or an AzureRMR resource object or resource ID to reuse an existing interface.
#' @param other_resources An optional list of other resources to include in the deployment.
#' @param ... For the specific VM configurations, other customisation arguments to be passed to `vm_config`.
#'
#' @export
vm_config <- function(image, keylogin, managed=TRUE,
                      datadisks=numeric(0),
                      nsg=nsg_config(),
                      ip=ip_config(),
                      vnet=vnet_config(),
                      nic=nic_config(),
                      other_resources=list())
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)

    stopifnot(inherits(image, "image_config"))
    stopifnot(is.list(datadisks) && all(sapply(datadisks, inherits, "datadisk_config")))

    obj <- list(
        image=image,
        keylogin=keylogin,
        managed=managed,
        datadisks=datadisks,
        nsg=nsg,
        ip=ip,
        vnet=vnet,
        nic=nic,
        other=other_resources
    )
    structure(obj, class="vm_config")
}

#' @rdname vm_config
#' @export
ubuntu_dsvm <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                        ...)
{
    disk0 <- datadisk_config(NULL, NULL, "fromImage", "Premium_LRS")
    vm_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"), keylogin, managed,
        c(list(disk0), datadisks), nsg, ...)
}

#' @rdname vm_config
#' @export
windows_dsvm <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    win_key_check(keylogin)
    vm_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"), FALSE, managed, datadisks, nsg, ...)
}

#' @rdname vm_config
#' @export
ubuntu_1604 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Canonical", "UbuntuServer", "16.04-LTS"), keylogin, managed, datadisks, nsg, ...)
}

#' @rdname vm_config
#' @export
ubuntu_1804 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"), keylogin, managed, datadisks, nsg, ...)
}

#' @rdname vm_config
#' @export
windows_2016 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    win_key_check(keylogin)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"), FALSE, managed,
              datadisks, nsg, ...)
}

#' @rdname vm_config
#' @export
windows_2019 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    win_key_check(keylogin)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter"), FALSE, managed,
              datadisks, nsg, ...)
}

#' @rdname vm_config
#' @export
redhat_7.6 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                       nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "7-RAW"), keylogin, managed, datadisks, nsg, ...)
}

#' @rdname vm_config
#' @export
redhat_8 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                     nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "8"), keylogin, managed, datadisks, nsg, ...)
}

#' @rdname vm_config
#' @export
debian9_backports <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                              nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Credativ", "Debian", "9-backports"), keylogin, managed, datadisks, nsg, ...)
}


win_key_check <- function(keylogin)
{
    if(keylogin)
        warning("Windows does not support SSH key logins", call.=FALSE)
}
