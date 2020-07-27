# virtual machine images ========================

#' @rdname vm_config
#' @export
ubuntu_dsvm <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
    nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
    ...)
{
    vm_config(image_config("microsoft-dsvm", "ubuntu-1804", "1804"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
ubuntu_dsvm_gen2 <- function(keylogin=TRUE, managed_identity=TRUE, datadisks=numeric(0),
    nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
    ...)
{
    vm_config(image_config("microsoft-dsvm", "ubuntu-1804", "1804-gen2"),
              keylogin=keylogin, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}

#' @rdname vm_config
#' @export
windows_dsvm <- function(keylogin=FALSE, managed_identity=TRUE, datadisks=numeric(0),
    nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    vm_config(image_config("microsoft-dsvm", "dsvm-win-2019", "server-2019"),
              keylogin=FALSE, managed_identity=managed_identity, datadisks=datadisks, nsg=nsg, ...)
}


# virtual machine scaleset images ===============

#' @rdname vmss_config
#' @export
ubuntu_dsvm_ss <- function(datadisks=numeric(0),
    nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
    load_balancer=lb_config(rules=list(lb_rule_ssh, lb_rule_jupyter, lb_rule_rstudio),
                            probes=list(lb_probe_ssh, lb_probe_jupyter, lb_probe_rstudio)),
    ...)
{
    vmss_config(image_config("microsoft-dsvm", "ubuntu-1804", "1804"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
ubuntu_dsvm_gen2_ss <- function(datadisks=numeric(0),
    nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
    load_balancer=lb_config(rules=list(lb_rule_ssh, lb_rule_jupyter, lb_rule_rstudio),
                            probes=list(lb_probe_ssh, lb_probe_jupyter, lb_probe_rstudio)),
    ...)
{
    vmss_config(image_config("microsoft-dsvm", "ubuntu-1804", "1804-gen2"),
                datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_dsvm_ss <- function(datadisks=numeric(0),
    nsg=nsg_config(list(nsg_rule_allow_rdp)),
    load_balancer=lb_config(rules=list(lb_rule_rdp), probes=list(lb_probe_rdp)),
    options=scaleset_options(keylogin=FALSE),
    ...)
{
    options$keylogin <- FALSE
    vmss_config(image_config("microsoft-dsvm", "dsvm-win-2019", "server-2019"),
                options=options, datadisks=datadisks, nsg=nsg, load_balancer=load_balancer, ...)
}

