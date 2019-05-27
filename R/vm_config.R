#' @export
vm_config <- R6::R6Class("vm_config",

public=list(

    imagePublisher=NULL,
    imageOffer=NULL,
    sku=NULL,
    nsrules=NULL,
    datadisks=NULL,
    key_available=NULL,

    initialize=function(publisher, offer, sku, os, default_datadisks=list())
    {
        os <- tolower(os)
        stopifnot(os %in% c("linux", "windows"))
        linux <- os == "linux"

        self$imagePublisher <- publisher
        self$imageOffer <- offer
        self$sku <- sku
        self$key_available <- linux
        self$nsrules <- if(linux) list(nsrule_allow_ssh) else list(nsrule_allow_rdp)
        self$datadisks=default_datadisks
    },

    build_template=function(key_login=TRUE, datadisks=0, nsrules=list(), add_msi=FALSE)
    {
        image <- list(imagePublisher=self$imagePublisher, imageOffer=self$imageOffer, vmSku=self$sku)
        datadisks <- build_datadisk_array(datadisks)

        build_template_internal(
            variables=image,
            nsrules=c(self$nsrules, nsrules),
            datadisks=c(self$datadisks, datadisks),
            vm=if(self$key_available && key_login) os_key_login else os_pwd_login
        )
    }
))


ubuntu_dsvm <- function()
vm_config$new("microsoft-dsvm", "linux-data-science-vm-ubuntu", "linuxdsvmubuntu", "linux", list(ubuntudsvm_datadisk))

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


