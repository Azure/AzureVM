context("Windows preset configs")

img_list <- list(
    windows_2016=list("MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter"),
    windows_2019=list("MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter")
)

test_that("VM/SS config works",
{
    key_user <- user_config("username", ssh="random key")
    Map(function(config, arglist)
    {
        vmconf <- get(config)
        vm <- vmconf()
        expect_is(vm, "vm_config")
        expect_identical(vm$image$publisher, arglist[[1]])
        expect_identical(vm$image$offer, arglist[[2]])
        expect_identical(vm$image$sku, arglist[[3]])
        expect_silent(build_template_definition(vm))
        expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

        vmssconf <- get(paste0(config, "_ss"))
        vmss <- vmssconf()
        expect_is(vmss, "vmss_config")
        expect_identical(vmss$image$publisher, arglist[[1]])
        expect_identical(vmss$image$offer, arglist[[2]])
        expect_identical(vmss$image$sku, arglist[[3]])
        expect_silent(build_template_definition(vmss))
        expect_silent(build_template_parameters(vmss, "vmname", key_user, "size", 5))
    }, names(img_list), img_list)
})


# test that predefined configurations deploy correctly, in parallel ===========

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")

rgname <- paste0("vm", make_name(20))
location <- "australiaeast"
user <- user_config("username",
    password=paste0(c(sample(letters, 5, TRUE), sample(LETTERS, 5, TRUE), "!@#"), collapse=""))
size <- "Standard_DS1_v2"

rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(rgname, location)

nworkers <- if(Sys.getenv("NOT_CRAN") == "") 2 else 10
cl <- parallel::makeCluster(nworkers)
parallel::clusterExport(cl, "rg", envir=environment())

test_that("VM deployment works",
{
    config_tester(img_list, cl, user, size)
})

teardown({
    suppressMessages(rg$delete(confirm=FALSE))
    parallel::stopCluster(cl)
})
