vmss_config <- function(image, keylogin, managed=TRUE, public_nodes=FALSE,
                        nsg=nsg_config(),
                        vnet=vnet_config(),
                        load_balancer=NULL,
                        load_balancer_address="dynamic",
                        autoscaler=NULL,
                        other_resources=list(),
                        variables=list())
{
    stopifnot(inherits(image, "image_config"))

    ip <- if(!is_empty(load_balancer))
    {
        if(is_resource(load_balancer_address))
            load_balancer_address
        else ip_config(load_balancer_address)
    }
    else NULL

    obj <- list(
        image=image,
        keylogin=keylogin,
        managed=managed,
        public_nodes=public_nodes,
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


ubuntu_dsvm_ss <- function(keylogin=TRUE, managed=TRUE, public_nodes=FALSE,
                           nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                           ...)
{
    vmss_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"),
                keylogin, managed, public_nodes, nsg, ...)
}

ubuntu_1804_ss <- function(keylogin=TRUE, managed=TRUE, public_nodes=FALSE,
                           nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                keylogin, managed, public_nodes, nsg, ...)
}

windows_2019_ss <- function(keylogin=FALSE, managed=TRUE, public_nodes=FALSE,
                            nsg=nsg_config(list(nsg_rule_allow_rdp)), ...)
{
    win_key_check(keylogin)
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                FALSE, managed, public_nodes, nsg, ...)
}

