# virtual machine images ========================

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

#' @rdname vm_config
#' @export
windows_2019_gen2 <- function(keylogin=FALSE, managed_identity=TRUE, datadisks=numeric(0),
                              nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter-gensecond"),
              keylogin=FALSE, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}


# virtual machine scaleset images ===============

#' @rdname vmss_config
#' @export
windows_2016_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                    probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    options$keylogin <- FALSE
    vmss_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"),
                options=options, datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_2019_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                    probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    options$keylogin <- FALSE
    vmss_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter"),
                options=options, datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_2019_gen2_ss <- function(datadisks=numeric(0),
                            nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                    probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    options$keylogin <- FALSE
    vmss_config(image_config("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter-gensecond"),
                options=options, datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}
