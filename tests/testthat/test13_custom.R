context("Custom deployments")

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

test_that("Custom vnet works",
{
    vmname <- paste0(sample(letters, 10, TRUE), collapse="")

    # should detect and fix subnet mismatch
    vnet <- vnet_config(address_space="10.1.0.0/16")
    vm <- rg$create_vm(vmname, user, size, vnet=vnet)
    expect_is(vm, "az_vm_template")

    expect_is(vm$get_vnet(), "az_resource")
})

test_that("Scaleset options work",
{
    ssname <- paste0(sample(letters, 10, TRUE), collapse="")
    size <- "Standard_DS3_v2"
    opts <- scaleset_options(
        managed_identity=FALSE,
        public=TRUE,
        priority="spot",
        delete_on_evict=TRUE,
        network_accel=TRUE,
        large_scaleset=TRUE,
        overprovision=FALSE
    )

    vmss <- rg$create_vm_scaleset(ssname, user, instances=3, size=size, options=opts)
    expect_is(vmss, "az_vmss_template")

    expect_is(vmss$get_public_ip_address(), "character")
    expect_is(vmss$get_vm_public_ip_addresses(), "character")
    expect_is(vmss$get_vm_private_ip_addresses(), "character")
    expect_true(is.null(vmss$identity))
})

rg$delete(confirm=FALSE)

