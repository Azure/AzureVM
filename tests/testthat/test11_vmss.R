context("VM scaleset interface")

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")

vmss_name <- paste0("vmss", paste0(sample(letters, 10, TRUE), collapse=""))
location <- "australiaeast"

# turn off parallelisation
maxpoolsize <- options(azure_vm_maxpoolsize=0)

rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(vmss_name, location)

test_that("Scaleset creation works",
{
    vm <- rg$create_vm_scaleset(vmss_name, user_config("username", "../resources/testkey.pub"), instances=3)
    expect_is(vm, "az_vmss_template")
})

test_that("Scaleset interaction works",
{
    vm <- rg$get_vm_scaleset(vmss_name)
    expect_is(vm, "az_vmss_template")

    expect_is(vm$get_public_ip_address(), "character")

    inst <- vm$list_instances()
    expect_is(inst, "list")

    expect_silent(vm$run_script("ls /tmp"))

    expect_is(vm$get_vm_private_ip_addresses(), "character")
    expect_is(vm$get_vm_public_ip_addresses(), "character")

    expect_is(vm$get_vm_private_ip_addresses(names(inst)[1:2]), "character")
    expect_is(vm$get_vm_public_ip_addresses(names(inst)[1:2]), "character")

    expect_is(vm$get_public_ip_resource(), "az_resource")
    expect_is(vm$get_vnet(), "az_resource")
    expect_is(vm$get_nsg(), "az_resource")
    expect_is(vm$get_load_balancer(), "az_resource")
    expect_is(vm$get_autoscaler(), "az_resource")

    expect_is(vm$identity, "list")
})

test_that("Scaleset deletion works",
{
    vm <- rg$get_vm_scaleset(vmss_name)
    vm$delete(confirm=FALSE)

    Sys.sleep(10)
    expect_true(is_empty(rg$list_resources()))
})

rg$delete(confirm=FALSE)
options(maxpoolsize)
