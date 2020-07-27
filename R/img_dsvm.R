#' @rdname vm_config
#' @export
ubuntu_dsvm <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                        dsvm_disk_type=c("Premium_LRS", "StandardSSD_LRS", "Standard_LRS"),
                        nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                        ...)
{
    if(is.numeric(datadisks))
        datadisks <- lapply(datadisks, datadisk_config)
    dsvm_disk_type <- match.arg(dsvm_disk_type)
    disk0 <- datadisk_config(NULL, NULL, "fromImage", dsvm_disk_type)
    vm_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=c(list(disk0), datadisks), nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
windows_dsvm <- function(keylogin=FALSE, managed_identity=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"),
              keylogin=FALSE, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}
