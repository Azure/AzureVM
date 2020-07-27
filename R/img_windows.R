#' @rdname vm_config
#' @export
windows_2016 <- function(keylogin=FALSE, managed_identity=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"),
              keylogin=FALSE, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
windows_2019 <- function(keylogin=FALSE, managed_identity=TRUE, datadisks=numeric(0),
                         nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter"),
              keylogin=FALSE, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}
