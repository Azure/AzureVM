#' @rdname vm_config
#' @export
centos_7.5 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                       nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("OpenLogic", "CentOS", "7.5"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
centos_7.6 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                       nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("OpenLogic", "CentOS", "7.6"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
centos_8.1 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                       nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("OpenLogic", "CentOS", "8_1"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

