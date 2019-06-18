context("Manual deletion")

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")

rgname <- paste0("vm", paste0(sample(letters, 10, TRUE), collapse=""))
location <- "australiaeast"
user <- user_config("username", "../resources/testkey.pub")
size <- "Standard_DS1_v2"

rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(rgname, location)

test_that("Resource sharing works",
{
    vmname1 <- paste0(sample(letters, 10, TRUE), collapse="")
    vmname2 <- paste0(sample(letters, 10, TRUE), collapse="")
    ssname <- paste0(sample(letters, 10, TRUE), collapse="")

    expect_is(rg$create_vm(vmname1, user, size), "az_vm_template")

    vnet <- rg$get_resource(type="Microsoft.Network/virtualNetworks", name=paste0(vmname1, "-vnet"))
    expect_is(vnet, "az_resource")

    expect_is(rg$create_vm(vmname2, user, size, vnet=vnet, nsg=NULL), "az_vm_template")

    expect_is(rg$create_vm_scaleset(ssname, user, instances=3, size=size, vnet=vnet, nsg=NULL), "az_vmss_template")

    expect_error(rg$get_resource(type="Microsoft.Network/virtualNetworks", name=paste0(vmname2, "-vnet")))
    expect_error(rg$get_resource(type="Microsoft.Network/virtualNetworks", name=paste0(vmname2, "-nsg")))

    rg$delete_vm_scaleset(ssname, confirm=FALSE)
    rg$delete_vm(vmname2, confirm=FALSE)
    rg$delete_vm(vmname1, confirm=FALSE)

    Sys.sleep(10)
    expect_true(is_empty(rg$list_resources()))
})

test_that("Custom resource works",
{
    vmname <- paste0(sample(letters, 10, TRUE), collapse="")

    stor <- list(
        type="Microsoft.Storage/storageAccounts",
        name=paste0(vmname, "stor"),
        apiVersion="2018-07-01",
        location="[variables('location')]",
        properties=list(supportsHttpsTrafficOnly=TRUE),
        sku=list(name="Standard_LRS"),
        kind="Storage"
    )
    expect_is(rg$create_vm(vmname, user, size, other_resources=list(stor)), "az_vm_template")

    expect_is(rg$get_resource(type="Microsoft.Storage/storageAccounts", name=paste0(vmname, "stor")), "az_resource")

    rg$delete_vm(vmname, confirm=FALSE)

    Sys.sleep(10)
    expect_true(is_empty(rg$list_resources()))
})

