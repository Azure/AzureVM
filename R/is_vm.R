#' Is an object an Azure VM
#'
#' @param object an R object.
#'
#' @return
#' `is_vm` and `is_vm_template` return TRUE for an object representing a virtual machine deployment (which will include other resources besides the VM itself).
#'
#' `is_vm_resource` returns TRUE for an object representing the specific VM resource.
#'
#' `is_vm_scaleset` and `is_vm_scaleset_template` return TRUE for an object representing a VM scaleset deployment.
#'
#' `is_vm_scaleset_resource` returns TRUE for an object representing the specific VM scaleset resource.
#'
#' @seealso
#' [create_vm], [create_vm_scaleset], [az_vm_template], [az_vm_resource], [az_vmss_template], [az_vmss_resource]
#' @export
is_vm <- function(object)
{
    R6::is.R6(object) && inherits(object, "az_vm_template")
}

#' @rdname is_vm
#' @export
is_vm_template <- is_vm

#' @rdname is_vm
#' @export
is_vm_resource <- function(object)
{
    R6::is.R6(object) && inherits(object, "az_vm_resource")
}

#' @rdname is_vm
#' @export
is_vm_scaleset <- function(object)
{
    R6::is.R6(object) && inherits(object, "az_vmss_template")
}

#' @rdname is_vm
#' @export
is_vm_scaleset_template <- is_vm_scaleset

#' @rdname is_vm
#' @export
is_vm_scaleset_resource <- function(object)
{
    R6::is.R6(object) && inherits(object, "az_vmss_resource")
}
