scaleset_options <- function(instances=2, priority="regular", on_evict="deallocate",
                             network_accel=FALSE, large_scaleset=FALSE,
                             overprovision=TRUE, upgrade_policy=list(mode="manual"))
{
    out <- list(
        instanceCount=instances,
        priority=priority,
        evictionPolicy=on_evict,
        enableAcceleratedNetworking=network_accel,
        singlePlacementGroup=large_scaleset,
        overprovision=overprovision,
        upgradePolicy=upgrade_policy
    )
    structure(out, class="scaleset_options")
}


lb_config <- function(rules=list(), probes=list())
{
    rule_probes <- sapply(rules, function(x) basename(x$properties$probe$id))
    probe_names <- sapply(probes, `[[`, "name")
    if(!is_empty(rule_probes))
    {
        if(is_empty(probe_names))
            stop("No probes specified", call.=FALSE)
        if(!all(rule_probes %in% probe_names))
            stop("Rule with no matching probe", call.=FALSE)
    }

    props <- list(loadBalancingRules=rules, probes=probes)
    structure(list(properties=props), class="lb_config")
}


lb_probe_config <- function(port, interval=5, fail_on=2, protocol="Tcp")
{
    name <- paste("probe", protocol, port, sep="-")
    props <- list(
        port=port,
        intervalInSeconds=interval,
        numberOfProbes=fail_on,
        protocol=protocol
    )

    structure(list(name=name, properties=props), class="lb_probe_config")
}


lb_rule_config <- function(name, frontend_port, backend_port=frontend_port, protocol="Tcp", timeout=5,
                           floating_ip=FALSE, probe_name=paste("probe", protocol, frontend_port, sep="-"))
{
    frontend_id <- "[concat(variables('lbId'), '/frontendIPConfigurations/frontendIp')]"
    backend_id <- "[concat(variables('lbId'), '/backendAddressPools/backendPool')]"
    probe_id <- sprintf("[concat(variables('lbId'), '/probes/%s')]", probe_name)

    props <- list(
        frontendIpConfiguration=list(id=frontend_id),
        backendAddressPool=list(id=backend_id),
        protocol=protocol,
        frontendPort=frontend_port,
        backendPort=backend_port,
        enableFloatingIp=floating_ip,
        idleTimeoutInMinutes=timeout,
        probe=list(id=probe_id)
    )

    structure(list(name=name, properties=props), class="lb_rule_config")
}


lb_rule_ssh <- lb_rule_config("lb-ssh", 22, 22, probe_name="probe-Tcp-22")
lb_rule_http <- lb_rule_config("lb-http", 80, 80, probe_name="probe-Tcp-80")
lb_rule_https <- lb_rule_config("lb-https", 443, 443, probe_name="probe-Tcp-443")
lb_rule_rdp <- lb_rule_config("lb-rdp", 3389, 3389, probe_name="probe-Tcp-3389")
lb_rule_jupyter <- lb_rule_config("lb-rdp", 8000, 8000, probe_name="probe-Tcp-8000")
lb_rule_rstudio <- lb_rule_config("lb-rstudio", 8787, 8787, probe_name="probe-Tcp-8787")

lb_probe_ssh <- lb_probe_config(22)
lb_probe_http <- lb_probe_config(80)
lb_probe_https <- lb_probe_config(443)
lb_probe_rdp <- lb_probe_config(3389)
lb_probe_jupyter <- lb_probe_config(8000)
lb_probe_rstudio <- lb_probe_config(8787)


autoscale_config <- function()
{

}

scaleset_nic_config <- function()
{

}
