# virtual machine images ========================

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


# virtual machine scaleset images ===============

#' @rdname vmss_config
#' @export
rhel_7.6_ss <- function(datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)),
                        load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                probes=list(lb_probe_ssh)),
                        ...)
{
    vmss_config(image_config("RedHat", "RHEL", "7-RAW"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
rhel_8_ss <- function(datadisks=numeric(0),
                      nsg=nsg_config(list(nsg_rule_allow_ssh)),
                      load_balancer=lb_config(rules=list(lb_rule_ssh),
                                              probes=list(lb_probe_ssh)),
                      ...)
{
    vmss_config(image_config("RedHat", "RHEL", "8"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
rhel_8.1_ss <- function(datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)),
                        load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                probes=list(lb_probe_ssh)),
                        ...)
{
    vmss_config(image_config("RedHat", "RHEL", "8.1"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
rhel_8.1_gen2_ss <- function(datadisks=numeric(0),
                             nsg=nsg_config(list(nsg_rule_allow_ssh)),
                             load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                     probes=list(lb_probe_ssh)),
                             ...)
{
    vmss_config(image_config("RedHat", "RHEL", "81gen2"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
rhel_8.2_ss <- function(datadisks=numeric(0),
                        nsg=nsg_config(list(nsg_rule_allow_ssh)),
                        load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                probes=list(lb_probe_ssh)),
                        ...)
{
    vmss_config(image_config("RedHat", "RHEL", "8.2"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
rhel_8.2_gen2_ss <- function(datadisks=numeric(0),
                             nsg=nsg_config(list(nsg_rule_allow_ssh)),
                             load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                     probes=list(lb_probe_ssh)),
                             ...)
{
    vmss_config(image_config("RedHat", "RHEL", "82gen2"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}


