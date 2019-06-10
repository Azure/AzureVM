#' Virtual machine scaleset configuration functions
#'
#' @param image For `vmss_config`, the VM image to deploy. This should be an object of class `image_config`, created by the function of the same name.
#' @param options Scaleset options, as obtained via a call to `scaleset_options`.
#' @param nsg The network security group for the scaleset. Can be a call to `nsg_config` to create a new NSG; an AzureRMR resource object or resource ID to reuse an existing NSG; or NULL to not use an NSG (not recommended).
#' @param vnet The virtual network for the scaleset. Can be a call to `vnet_config` to create a new virtual network, or an AzureRMR resource object or resource ID to reuse an existing virtual network.
#' @param load_balancer The load balancer for the scaleset. Can be a call to `lb_config` to create a new load balancer;  an AzureRMR resource object or resource ID to reuse an existing load balancer; or NULL if load balancing is not required.
#' @param load_balancer_address The public IP address for the load balancer. Can be a call to `ip_config` to create a new IP address, or an AzureRMR resource object or resource ID to reuse an existing address resource. Ignored if `load_balancer` is NULL.
#' @param autoscaler The autoscaler for the scaleset. Can be a call to `autoscaler_config` to create a new autoscaler; an AzureRMR resource object or resource ID to reuse an existing autoscaler; or NULL if autoscaling is not required.
#' @param other_resources An optional list of other resources to include in the deployment.
#' @param variables An optional named list of variables to add to the template.
#' @param ... For the specific VM configurations, other customisation arguments to be passed to `vm_config`.
#'
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

    # make IP sku, balancer sku and scaleset size consistent with each other
    load_balancer <- vmss_fixup_lb(options, load_balancer)
    ip <- vmss_fixup_ip(options, load_balancer, load_balancer_address)

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


vmss_fixup_lb <- function(options, lb)
{
    # don't try to fix load balancer if not created here
    if(is.null(lb) || !inherits(lb, "lb_config"))
        return(lb)

    # for a large scaleset, must set sku=standard
    if(!options$params$singlePlacementGroup)
    {
        if(is.null(lb$type))
            lb$type <- "standard"
        else if(tolower(lb$type) != "standard")
            stop("Load balancer type must be 'standard' for large scalesets", call.=FALSE)
    }
    else
    {
        if(is.null(lb$type))
            lb$type <- "basic"
    }

    lb
}


vmss_fixup_ip <- function(options, lb, ip)
{
    # IP address only required if load balancer is present
    if(is.null(lb))
        return(NULL)

    # don't try to fix IP if load balancer was provided as a resource id
    if(is.character(lb))
        return(ip)

    # don't try to fix IP if not created here
    if(is.null(ip) || !inherits(ip, "ip_config"))
        return(ip)

    lb_type <- if(is_resource(lb))
        lb$sku$name
    else lb$type

    # for a large scaleset, must set sku=standard, allocation=static
    if(!options$params$singlePlacementGroup)
    {
        if(is.null(ip$type))
            ip$type <- "standard"
        else if(tolower(ip$type) != "standard")
            stop("Load balancer IP address type must be 'standard' for large scalesets", call.=FALSE)

        if(is.null(ip$dynamic))
            ip$dynamic <- FALSE
        else if(ip$dynamic)
            stop("Load balancer dynamic IP address not supported for large scalesets", call.=FALSE)
    }
    else
    {
        # defaults for small scaleset: sku=load balancer sku, allocation=dynamic
        if(is.null(ip$type))
            ip$type <- lb_type
        if(is.null(ip$dynamic))
            ip$dynamic <- tolower(ip$type) == "basic"
    }

    # check consistency
    if(tolower(ip$type) == "standard" && ip$dynamic)
        stop("Standard IP address type does not support dynamic allocation", call.=FALSE)

    ip
}


#' @rdname vmss_config
#' @export
ubuntu_dsvm_ss <- function(nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                           load_balancer=lb_config(rules=list(lb_rule_ssh, lb_rule_jupyter, lb_rule_rstudio),
                                                   probes=list(lb_probe_ssh, lb_probe_jupyter, lb_probe_rstudio)),
                           ...)
{
    vmss_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"),
                nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_dsvm_ss <- function(nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                   probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    vmss_config(image_config("microsoft-dsvm", "dsvm-windows", "server-2016"),
                options=options, nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
ubuntu_1804_ss <- function(nsg=nsg_config(list(nsg_rule_allow_ssh)),
                           load_balancer=lb_config(rules=list(lb_rule_ssh),
                                                   probes=list(lb_probe_ssh)),
                           ...)
{
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                nsg=nsg, load_balancer=load_balancer, ...)
}

#' @rdname vmss_config
#' @export
windows_2019_ss <- function(nsg=nsg_config(list(nsg_rule_allow_rdp)),
                            load_balancer=lb_config(rules=list(lb_rule_rdp),
                                                    probes=list(lb_probe_rdp)),
                            options=scaleset_options(keylogin=FALSE),
                            ...)
{
    win_key_check(scaleset_options$keylogin)
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                options=options, nsg=nsg, load_balancer=load_balancer, ...)
}


#' Virtual machine scaleset options
#'
#' @param keylogin Boolean: whether to use an SSH public key to login (TRUE) or a password (FALSE). Note that Windows does not support SSH key logins.
#' @param managed Whether to provide a managed system identity for the VM.
#' @param public Whether the instances (nodes) of the scaleset should be visible from the public internet.
#' @param low_priority Whether to use low-priority VMs. Note that this option is only available for certain VM sizes.
#' @param delete_on_evict If low-priority VMs are being used, whether evicting (shutting down) a VM should delete it, as opposed to just deallocating it.
#' @param network_accel Whether to enable accelerated networking.
#' @param large_scaleset Whether to enable scaleset sizes > 100 instances.
#' @param overprovision Whether to overprovision the scaleset on creation.
#' @param upgrade_policy A list, giving the VM upgrade policy for the scaleset.
#'
#' @export
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

