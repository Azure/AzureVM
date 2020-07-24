#' Resource configuration functions for a virtual machine deployment
#'
#' @param username For `user_config`, the name for the admin user account.
#' @param sshkey For `user_config`, The SSH public key. This can be supplied in a number of ways: as a string with the key itself; the name of the public key file; or an `AzureRMR::az_resource` object pointing to an SSH public key resource (of type "Microsoft.Compute/sshPublicKey"). See the example below.
#' @param password For `user_config`, the admin password. Supply either `sshkey` or `password`, but not both; also, note that Windows does not support SSH logins.
#' @param size For `datadisk_config`, the size of the data disk in GB. St this to NULL for a disk that will be created from an image.
#' @param name For `datadisk_config`, the disk name. Duplicate names will automatically be disambiguated prior to VM deployment.
#' @param create For `datadisk_config`, the creation method. Can be "empty" (the default) to create a blank disk, or "fromImage" to use an image.
#' @param type For `datadisk_config`, the disk type (SKU). Can be "Standard_LRS", "StandardSSD_LRS" (the default), "Premium_LRS" or "UltraSSD_LRS". Of these, "Standard_LRS" uses hard disks and the others use SSDs as the underlying hardware.
#' @param write_accelerator For `datadisk_config`, whether the disk should have write acceleration enabled.
#' @param publisher,offer,sku,version For `image_config`, the details for a marketplace image.
#' @param id For `image_config`, the resource ID for a disk to use as a custom image.
#'
#' @examples
#' \dontrun{
#'
#' # create an SSH public key resource in Azure
#' keyres <- rg$create_resource(type="Microsoft.Compute/sshPublicKey", name="mysshkey")
#'
#' # generate the public and private keys
#' keys <- keyres$do_operation("generateKeyPair", http_verb="POST")
#'
#' # save the private key (IMPORTANT)
#' writeBin(keys$privateKey, "mysshkey.pem")
#'
#' # create a new VM using the public key resource for authentication
#' # you can then login to the VM with ssh -i mysshkey.pem <vm address>
#' rg$create_vm("mynewvm", user_config("myusername", sshkey=keyres), config="ubuntu_vm")
#'
#' }
#'
#' @rdname vm_resource_config
#' @export
user_config <- function(username, sshkey=NULL, password=NULL)
{
    keyres <- is_resource(sshkey) && tolower(sshkey$type) == "microsoft.compute/sshpublickeys"
    key <- is.character(sshkey) || keyres
    pwd <- is.character(password)

    if(!pwd && !key)
        stop("Must supply either a login password or SSH key", call.=FALSE)
    if(pwd && key)
        stop("Supply either a login password or SSH key, but not both", call.=FALSE)

    if(keyres)
    {
        sshkey <- sshkey$properties$publicKey
        if(is_empty(sshkey))
            stop("Supplied public key resource is uninitialized, call the generateKeyPair() method first and save the returned keys",
                 call.=FALSE)
    }
    else if(key && file.exists(sshkey))
        sshkey <- readLines(sshkey)

    structure(list(user=username, key=sshkey, pwd=password), class="user_config")
}


#' @rdname vm_resource_config
#' @export
datadisk_config <- function(size, name="datadisk", create="empty",
                            type=c("StandardSSD_LRS", "Premium_LRS", "Standard_LRS", "UltraSSD_LRS"),
                            write_accelerator=FALSE)
{
    type <- match.arg(type)
    vm_caching <- if(type == "Premium_LRS") "ReadOnly" else "None"
    vm_create <- if(create == "empty") "attach" else "fromImage"
    vm_storage <- if(create == "empty") NULL else type

    vm_spec <- list(
        createOption=vm_create,
        caching=vm_caching,
        writeAcceleratorEnabled=write_accelerator,
        storageAccountType=vm_storage,
        diskSizeGB=NULL,
        id=NULL,
        name=name
    )

    res_spec <- if(!is.null(size))
        list(
            diskSizeGB=size,
            sku=type,
            creationData=list(createOption=create),
            name=name
        )
    else NULL

    structure(list(res_spec=res_spec, vm_spec=vm_spec), class="datadisk_config")
}


#' @rdname vm_resource_config
#' @export
image_config <- function(publisher=NULL, offer=NULL, sku=NULL, version="latest", id=NULL)
{
    if(!is.null(publisher) && !is.null(offer) && !is.null(sku))
    {
        structure(list(publisher=publisher, offer=offer, sku=sku, version=version),
                  class=c("image_marketplace", "image_config"))
    }
    else if(!is.null(id))
    {
        structure(list(id=id),
                  class=c("image_custom", "image_config"))
    }
    else stop("Invalid image configuration", call.=FALSE)
}

