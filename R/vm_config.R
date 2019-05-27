#' @export
vm_config <- R6::R6Class("vm_config",

public=list(

    imagePublisher=NULL,
    imageOffer=NULL,
    sku=NULL,
    nsrules=NULL,
    datadisks=NULL,
    key_available=NULL,

    initialize=function(publisher, offer, sku, os, default_datadisks=list(), default_nsrules=list())
    {
        os <- tolower(os)
        stopifnot(os %in% c("linux", "windows"))
        linux <- os == "linux"

        self$imagePublisher <- publisher
        self$imageOffer <- offer
        self$sku <- sku
        self$key_available <- linux
        self$nsrules <- c(if(linux) list(nsrule_allow_ssh) else list(nsrule_allow_rdp), default_nsrules)
        self$datadisks=default_datadisks
    },

    build_template=function(key_login=TRUE, datadisk_sizes=numeric(0), msi=FALSE, nsrules=list(),
                            nic=list(), nsg=list(), vnet=list(), ip=list(), vm=list(), other_resources=list(),
                            as_json=TRUE)
    {
        datadisks <- lapply(seq_along(datadisk_sizes), function(i)
        {
            disk <- blank_datadisk
            disk$name <- sprintf("[concat(parameters(\'vmName\'), \'-data-%s\')]", i)
            disk$diskSizeGB <- datadisk_sizes[i]
            disk
        })

        variables <- modifyList(tpl_variables_default,
            list(imagePublisher=self$imagePublisher, imageOffer=self$imageOffer, vmSku=self$sku))

        datadisks <- c(self$datadisks, datadisks)
        for(i in seq_along(datadisks))
            datadisks[[i]]$lun <- i - 1

        nic <- modifyList(nic_default, nic)
        nsg <- modifyList(nsg_default, nsg)
        vnet <- modifyList(vnet_default, vnet)
        ip <- modifyList(ip_default, ip)
        vm <- modifyList(vm_default, vm)

        nsg$properties$securityRules <- c(self$nsrules, nsrules)
        if(!is_empty(datadisks))
            vm$properties$storageProfile$datadisks <- datadisks

        tpl <- list(
            `$schema`="https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            contentVersion="1.0.0.0",
            parameters=tpl_parameters_default,
            variables=variables,
            resources=c(list(nic, nsg, vnet, ip, vm), other_resources),
            outputs=tpl_outputs_default
        )

        if(as_json) jsonlite::toJSON(tpl, pretty=TRUE, auto_unbox=TRUE) else tpl
    },

    build_parameters=function()
    {}
))


ubuntu_dsvm <- function()
vm_config$new("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu", "linux",
    list(ubuntudsvm_datadisk),
    list(nsrule_allow_jupyter, nsrule_allow_rstudio))

windows_dsvm <- function()
vm_config$new("microsoft-dsvm", "dsvm-windows", "server-2016", "windows")

ubuntu_1604 <- function()
vm_config$new("Canonical", "UbuntuServer", "16.04-LTS", "linux")

ubuntu_1804 <- function()
vm_config$new("Canonical", "UbuntuServer", "18.04-LTS", "linux")

windows_2016 <- function()
vm_config$new("MicrosoftWindowsServer", "WindowsServer", "windows_2016", "windows")

windows_2019 <- function()
vm_config$new("MicrosoftWindowsServer", "WindowsServer", "windows_2019", "windows")

custom_vm <- function(publisher, offer, sku, os, default_datadisks=list(), default_nsrules=list())
vm_config$new(publisher, offer, sku, os, default_datadisks, default_nsrules())

