#' @export
vm_config <- function(image, keylogin, managed=TRUE, datadisks=list(), nsg_rules=list(),
                      nic=list(), nsg=list(), vnet=list(), ip=list(), vm=list(), other_resources=list())
{
    stopifnot(inherits(image, "image_config"))
    stopifnot(is.list(datadisks) && all(sapply(datadisks, inherits, "datadisk_config")))
    stopifnot(is.list(nsg_rules) && all(sapply(nsg_rules, inherits, "nsg_rule_config")))

    obj <- list(image=image, keylogin=keylogin, managed=managed, datadisks=datadisks, nsg_rules=nsg_rules)

    obj$nic <- resource_config(nic_default, nic)
    obj$nsg <- resource_config(nsg_default, nsg)
    obj$vnet <- resource_config(vnet_default, vnet)
    obj$ip <- resource_config(ip_default, ip)
    obj$vm <- resource_config(vm_default, vm)

    obj$other <- other_resources

    structure(obj, class="vm_config")
}


#' @export
ubuntu_dsvm <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg_rules=list(
                            nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio),
                        ...)
{
    disk0 <- datadisk_config(NULL, NULL, "fromImage", "Premium_LRS")
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"), keylogin, managed,
              c(list(disk0), datadisks), nsg_rules, ...)
}

#' @export
windows_dsvm <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg_rules=list(nsg_rule_allow_rdp), ...)
{
    if(keylogin)
        warning("Windows does not support SSH key logins", call.=FALSE)
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"), FALSE, managed, datadisks, nsg_rules, ...)
}

#' @export
ubuntu_1604 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg_rules=list(nsg_rule_allow_ssh), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("Canonical", "UbuntuServer", "16.04-LTS"), keylogin, managed, datadisks, nsg_rules, ...)
}

#' @export
ubuntu_1804 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg_rules=list(nsg_rule_allow_ssh), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"), keylogin, managed, datadisks, nsg_rules, ...)
}

#' @export
windows_2016 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg_rules=list(nsg_rule_allow_rdp), ...)
{
    if(keylogin)
        warning("Windows does not support SSH key logins", call.=FALSE)
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"), FALSE, managed,
              datadisks, nsg_rules, ...)
}

#' @export
windows_2019 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg_rules=list(nsg_rule_allow_rdp), ...)
{
    if(keylogin)
        warning("Windows does not support SSH key logins", call.=FALSE)
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter"), FALSE, managed,
              datadisks, nsg_rules, ...)
}

#' @export
redhat_7.6 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                       nsg_rules=list(nsg_rule_allow_ssh), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("RedHat", "RHEL", "7-RAW"), keylogin, managed, datadisks, nsg_rules, ...)
}

#' @export
redhat_8 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                     nsg_rules=list(nsg_rule_allow_ssh), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("RedHat", "RHEL", "8"), keylogin, managed, datadisks, nsg_rules, ...)
}

#' @export
debian9_backports <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                              nsg_rules=list(nsg_rule_allow_ssh), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("Credativ", "Debian", "9-backports"), keylogin, managed, datadisks, nsg_rules, ...)
}

