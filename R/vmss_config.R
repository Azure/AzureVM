vmss_config <- function(image, keylogin, managed=TRUE, public=FALSE,
                        nsg=nsg_config(),
                        vnet=vnet_config(),
                        load_balancer=NULL,
                        autoscaler=NULL,
                        other_resources=list())
{
    stopifnot(inherits(image, "image_config"))
    stopifnot(is.list(datadisks) && all(sapply(datadisks, inherits, "datadisk_config")))

    obj <- list(
        image=image,
        keylogin=keylogin,
        managed=managed,
        public=public,
        nsg=nsg,
        vnet=vnet,
        lb=load_balancer,
        autoscaler=autoscaler,
        other=other_resources
    )
    structure(obj, class="vmss_config")
}


ubuntu_dsvm_ss <- function(keylogin=TRUE, managed=TRUE, public=FALSE,
                           nsg=nsg_config(list(nsg_rule_allow_ssh, nsg_rule_allow_jupyter, nsg_rule_allow_rstudio)),
                           ...)
{
    vmss_config(image_config("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu"),
                keylogin, managed, public, nsg, ...)
}

ubuntu_1804_ss <- function(keylogin=TRUE, managed=TRUE, public=FALSE,
                           nsg=nsg_config(list(nsg_rule_allow_ssh)), ...)
{
    vmss_config(image_config("Canonical", "UbuntuServer", "18.04-LTS"),
                keylogin, managed, public, nsg, ...)
}

