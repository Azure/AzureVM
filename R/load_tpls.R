lapply(dir("inst/tpl", pattern="\\.json$"), function(f)
{
    objname <- sub("\\.json$", "", f)
    obj <- jsonlite::fromJSON(file.path("inst/tpl", f), simplifyVector=FALSE)

    if(grepl("nsg_rule", objname, fixed=TRUE))
        class(obj) <- "nsg_rule_config"

    assign(objname, obj, parent.env(environment()))
})


#' Network security rules
#'
#' @section Usage:
#' ```
#' nsg_rule_allow_http
#' nsg_rule_allow_https
#' nsg_rule_allow_jupyter
#' nsg_rule_allow_rdp
#' nsg_rule_allow_rstudio
#' nsg_rule_allow_ssh
#' ```
#' @section Details:
#' These are the default network security rules provided by AzureVM. They are setup to allow specific ports through the Azure firewall. You should only allow the ports that you need.
#' - HTTP: TCP port 80
#' - HTTPS: TCP port 443
#' - JupyterHub: TCP port 8000
#' - RDP: TCP port 3389
#' - RStudio Server: TCP port 8787
#' - SSH: TCP port 22
#' @docType data
#' @rdname nsg_rule
#' @name nsg_rule
#' @aliases nsg_rule_allow_http nsg_rule_allow_https nsg_rule_allow_jupyter nsg_rule_allow_rdp nsg_rule_allow_rstudio nsg_rule_allow_ssh
#' @exportPattern ^nsg_rule_
NULL
