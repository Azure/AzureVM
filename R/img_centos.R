# virtual machine images ========================

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


# virtual machine scaleset images ===============

#' @rdname vmss_config
#' @export
centos_7.5_ss <- function(datadisks=numeric(0),
                          nsg=nsg_config(list(nsg_rule_allow_ssh)),
                          load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                  probes=list(lb_probe_ssh)),
                          ...)
{
    vmss_config(image_config("OpenLogic", "CentOS", "7.5"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
centos_7.6_ss <- function(datadisks=numeric(0),
                          nsg=nsg_config(list(nsg_rule_allow_ssh)),
                          load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                  probes=list(lb_probe_ssh)),
                          ...)
{
    vmss_config(image_config("OpenLogic", "CentOS", "7.6"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
centos_8.1_ss <- function(datadisks=numeric(0),
                          nsg=nsg_config(list(nsg_rule_allow_ssh)),
                          load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                  probes=list(lb_probe_ssh)),
                          ...)
{
    vmss_config(image_config("OpenLogic", "CentOS", "8_1"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}


