#' @rdname vm_config
#' @export
debian_8_backports <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                               nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Credativ", "Debian", "8-backports"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
debian_9_backports <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                               nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Credativ", "Debian", "9-backports"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
debian_10_backports <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                                nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Debian", "Debian-10", "10-backports"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
debian_10_backports_gen2 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
                                     nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vm_config(image_config("Debian", "Debian-10", "10-backports-gen2"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

