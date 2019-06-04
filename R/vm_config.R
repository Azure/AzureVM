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

#' @export
ubuntu_dsvm <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                        ...)
{
    disk0 <- datadisk_config(NULL, NULL, "fromImage", "Premium_LRS")
    vm_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"), keylogin, managed,
        c(list(disk0), datadisks), nsg, ...)
}

#' @export
windows_dsvm <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    win_key_check(keylogin)
    vm_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"), FALSE, managed, datadisks, nsg, ...)
}

#' @export
ubuntu_1604 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Canonical", "UbuntuServer", "16.04-LTS"), keylogin, managed, datadisks, nsg, ...)
}

#' @export
ubuntu_1804 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"), keylogin, managed, datadisks, nsg, ...)
}

#' @export
windows_2016 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    win_key_check(keylogin)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"), FALSE, managed,
              datadisks, nsg, ...)
}

#' @export
windows_2019 <- function(keylogin=FALSE, managed=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    win_key_check(keylogin)
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter"), FALSE, managed,
              datadisks, nsg, ...)
}

#' @export
redhat_7.6 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                       nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "7-RAW"), keylogin, managed, datadisks, nsg, ...)
}

#' @export
redhat_8 <- function(keylogin=TRUE, managed=TRUE, datadisks=numeric(0),
                     nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "8"), keylogin, managed, datadisks, nsg, ...)
}

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
