context("Centos preset configs")

img_list <- list(
    centos_7.5=list("OpenLogic", "CentOS", "7.5"),
    centos_7.6=list("OpenLogic", "CentOS", "7.6"),
    centos_8.1=list("OpenLogic", "CentOS", "8_1")
)

test_that("VM/SS config works",
{
    user <- user_config("username", ssh="random key")
    config_unit_tester(img_list, user)
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

rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(rgname, location)

nworkers <- if(Sys.getenv("NOT_CRAN") == "") 2 else 10
cl <- parallel::makeCluster(nworkers)
parallel::clusterExport(cl, "rg", envir=environment())

test_that("VM/SS deployment works",
{
    user <- user_config("username", "../resources/testkey.pub")
    size <- "Standard_DS1_v2"
    config_integration_tester(img_list, cl, user, size)
})

teardown({
    suppressMessages(rg$delete(confirm=FALSE))
    parallel::stopCluster(cl)
})
