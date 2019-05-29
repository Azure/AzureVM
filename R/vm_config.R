vm_config <- function(image, keylogin, msi, datadisks, nsrules,
                      nic=list(), nsg=list(), vnet=list(), ip=list(), vm=list(), other_resources=list())
{
    obj <- list(image=image, keylogin=keylogin, msi=msi, datadisks=datadisks, nsrules=nsrules)

    obj$nic <- resource_config(nic_default, nic)
    obj$nsg <- resource_config(nsg_default, nsg)
    obj$vnet <- resource_config(vnet_default, vnet)
    obj$ip <- resource_config(ip_default, ip)
    obj$vm <- resource_config(vm_default, vm)

    obj$other <- other_resources

    structure(obj, "vm_config")
}


#' @export
ubuntu_dsvm <- function(keylogin=TRUE, msi=TRUE, datadisks=numeric(0),
                        nsrules=list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio),
                        ...)
{
    disk0 <- datadisk_config(NULL, "fromImage", "Premium_LRS")
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"), keylogin, msi,
              c(disk0, datadisks), nsrules, ...)
}

#' @export
windows_dsvm <- function(keylogin=FALSE, msi=TRUE, datadisks=numeric(0), nsrules=list(nsg_rule_allow_rdp), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"), FALSE, msi, datadisks, nsrules, ...)
}

#' @export
ubuntu_1604 <- function(keylogin=TRUE, msi=TRUE, datadisks=numeric(0), nsrules=list(nsg_rule_allow_ssh), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("Canonical", "UbuntuServer", "16.04-LTS"), keylogin, msi, datadisks, nsrules, ...)
}

#' @export
ubuntu_1804 <- function(keylogin=TRUE, msi=TRUE, datadisks=numeric(0), nsrules=list(nsg_rule_allow_ssh), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"), keylogin, msi, datadisks, nsrules, ...)
}

#' @export
windows_2016 <- function(keylogin=FALSE, msi=TRUE, datadisks=numeric(0), nsrules=list(nsg_rule_allow_rdp), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "windows_2016"), FALSE, msi,
              datadisks, nsrules, ...)
}

#' @export
windows_2019 <- function(keylogin=FALSE, msi=TRUE, datadisks=numeric(0), nsrules=list(nsg_rule_allow_rdp), ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "windows_2019"), FALSE, msi,
              datadisks, nsrules, ...)
}

#' @export
custom_vm <- function(datadisks=numeric(0), nsrules=list(), image, os, ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    vm_config(image, os, datadisks, nsrules, ...)
}

