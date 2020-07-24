context("Using SSH public key resource")

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")

rgname <- paste0("vm", paste0(sample(letters, 10, TRUE), collapse=""))
location <- "australiaeast"
size <- "Standard_DS1_v2"

rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(rgname, location)

test_that("Deploying VM with SSH public key resource works",
{
    vmname <- paste0(sample(letters, 10, TRUE), collapse="")
    keyname <- vmname
    expect_silent(keyres <- rg$create_resource(type="Microsoft.Compute/sshPublicKeys", name=keyname))
    expect_silent(keys <- keyres$do_operation("generateKeyPair", http_verb="POST"))
    expect_true(is.character(keys$publicKey))
    keyres$sync_fields()

    user <- user_config("username", keyres)
    vm <- rg$create_vm(vmname, user, size, config="ubuntu_20.04")
    expect_is(vm, "az_vm_template")
})

rg$delete(confirm=FALSE)

