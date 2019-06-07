#' @export
vmss_config <- function(image, options=scaleset_options(),
                        nsg=nsg_config(),
                        vnet=vnet_config(),
                        load_balancer=lb_config(),
                        load_balancer_address=ip_config(),
                        autoscaler=autoscaler_config(),
                        other_resources=list(),
                        variables=list())
{
    stopifnot(inherits(image, "image_config"))
    stopifnot(inherits(options, "scaleset_options"))

    ip <- if(!is_empty(load_balancer)) load_balancer_address else NULL

    obj <- list(
        image=image,
        options=options,
        nsg=nsg,
        vnet=vnet,
        lb=load_balancer,
        ip=ip,
        as=autoscaler,
        other=other_resources,
        variables=variables
    )
    structure(obj, class="vmss_config")
}


#' @export
ubuntu_dsvm_ss <- function(nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                           load_balancer=lb_config(rules=list(lb_rule_ssh, lb_rule_jupyter, lb_rule_rstudio),
                                                   probes=list(lb_probe_ssh, lb_probe_jupyter, lb_probe_rstudio)),
                           ...)
{
    vmss_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"),
                nsg=nsg, load_balancer=load_balancer, ...)
}

#' @export
ubuntu_1804_ss <- function(nsg=nsg_config(list(nsg_rule_allow_ssh)),
                           load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                   probes=list(lb_probe_ssh)),
                           ...)
{
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                nsg=nsg, load_balancer=load_balancer, ...)
}

#' @export
windows_2019_ss <- function(nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                    probes=list(lb_probe_rdp)),
                            scaleset_options=scaleset_options(keylogin=FALSE),
                            ...)
{
    win_key_check(scaleset_options$keylogin)
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                scaleset_options=scaleset_options, nsg=nsg, load_balancer=load_balancer, ...)
}


scaleset_options <- function(keylogin=TRUE, managed=TRUE, public=FALSE,
                             low_priority=FALSE, delete_on_evict=FALSE,
                             network_accel=FALSE, large_scaleset=FALSE,
                             overprovision=TRUE, upgrade_policy=list(mode="manual"))
{
    params <- list(
        priority=if(low_priority) "low" else "regular",
        evictionPolicy=if(delete_on_evict) "delete" else "deallocate",
        enableAcceleratedNetworking=network_accel,
        singlePlacementGroup=!large_scaleset,
        overprovision=overprovision,
        upgradePolicy=upgrade_policy
    )

    out <- list(keylogin=keylogin, managed=managed, public=public, params=params)
    structure(out, class="scaleset_options")
}

