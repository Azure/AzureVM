context("Datadisks")

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")

rgname <- paste0("vm", paste0(sample(letters, 10, TRUE), collapse=""))
location <- "australiaeast"
user <- user_config("username", "../resources/testkey.pub")
size <- "Standard_D1_v2"

rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(rgname, location)

test_that("OS disk type works",
{
    vmname <- paste0(sample(letters, 10, TRUE), collapse="")
    vm <- rg$create_vm(vmname, user, size, config="ubuntu_18.04",
        os_disk_type="StandardSSD_LRS")
    expect_is(vm, "az_vm_template")

    vmssname <- paste0(sample(letters, 10, TRUE), collapse="")
    vmss <- rg$create_vm_scaleset(vmssname, user, instances=3, size=size, config="ubuntu_18.04_ss",
        options=scaleset_options(os_disk_type="StandardSSD_LRS"),
        nsg=NULL, autoscaler=NULL, load_balancer=NULL)
    expect_is(vmss, "az_vmss_template")
})

test_that("Data disk type works",
{
    vmname <- paste0(sample(letters, 10, TRUE), collapse="")
    vm <- rg$create_vm(vmname, user, size, config="ubuntu_dsvm",
        os_disk_type="StandardSSD_LRS", dsvm_disk_type="Standard_LRS",
        datadisks=list(datadisk_config(400, type="Standard_LRS")))
    expect_is(vm, "az_vm_template")

    vmssname <- paste0(sample(letters, 10, TRUE), collapse="")
    vmss <- rg$create_vm_scaleset(vmssname, user, instances=3, size=size, config="ubuntu_dsvm_ss",
        options=scaleset_options(os_disk_type="StandardSSD_LRS"),
        dsvm_disk_type="Standard_LRS",
        datadisks=list(datadisk_config(400, type="Standard_LRS")),
        nsg=NULL, autoscaler=NULL, load_balancer=NULL)
    expect_is(vmss, "az_vmss_template")
})

rg$delete(confirm=FALSE)

