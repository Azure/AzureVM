context("VM interface")

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")

vm_name <- paste0("vm", paste0(sample(letters, 10, TRUE), collapse=""))
location <- "australiaeast"

rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(vm_name, location)

test_that("VM creation works",
{
    vm <- rg$create_vm(vm_name, user_config("username", "../resources/testkey.pub"), "Standard_DS1_v2")
    expect_is(vm, "az_vm_template")
})

test_that("VM interaction works",
{
    vm <- rg$get_vm(vm_name)
    expect_is(vm, "az_vm_template")

    expect_silent(vm$run_script("ls /tmp"))

    vm$stop(deallocate=FALSE, wait=TRUE)
    status <- vm$sync_vm_status()
    expect_true(status["PowerState"] == "stopped")

    vm$resize("Standard_DS2_v2", wait=TRUE)
    expect_true(vm$.__enclos_env__$private$vm$properties$hardwareProfile == "Standard_DS2_v2")

    vm$start(wait=TRUE)
    status <- vm$sync_vm_status()
    expect_true(status["PowerState"] == "running")

    expect_is(vm$get_public_ip_address(), "character")
    expect_is(vm$get_private_ip_address(), "character")

    expect_is(vm$identity, "list")

    expect_is(vm$get_public_ip_resource(), "az_resource")
    expect_is(vm$get_nic(), "az_resource")
    expect_is(vm$get_vnet(), "az_resource")
    expect_is(vm$get_nsg(), "az_resource")
    expect_is(vm$get_disk("os"), "az_resource")

    expect_message(vm$redeploy())
})

test_that("VM deletion works",
{
    vm <- rg$get_vm(vm_name)
    vm$delete(confirm=FALSE)

    Sys.sleep(10)
    expect_true(is_empty(rg$list_resources()))
})

rg$delete(confirm=FALSE)

