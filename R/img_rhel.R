#' @rdname vm_config
#' @export
rhel_7.6 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                     nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "7-RAW"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
rhel_8 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                   nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "8"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
rhel_8.1 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                     nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "8.1"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
rhel_8.1_gen2 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                          nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "81gen2"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
rhel_8.2 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                     nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "8.2"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
rhel_8.2_gen2 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                          nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("RedHat", "RHEL", "82gen2"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}



