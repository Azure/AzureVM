#' @import AzureRMR
NULL

#' @export
AzureRMR::build_template_definition

#' @export
AzureRMR::build_template_parameters

globalVariables(c("self", "pool"), "AzureVM")

.AzureVM <- new.env()


# adding methods to classes in external package must go in .onLoad
.onLoad <- function(libname, pkgname)
{
    add_sub_methods()
    add_rg_methods()
    add_defunct_methods()
    options(azure_vm_minpoolsize=2)
    options(azure_vm_maxpoolsize=10)
}

