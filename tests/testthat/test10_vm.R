context("VM interface")

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")


sub <- AzureRMR::az_rm$new(tenant=tenant, app=app, password=password)$get_subscription(subscription)

rgname <- paste(sample(letters, 20, replace=TRUE), collapse="")
winvm_name <- paste0("win", paste0(sample(letters, 10, TRUE), collapse=""))
luxvm_name <- paste0("lux", paste0(sample(letters, 10, TRUE), collapse=""))
winvmrg_name <- paste0("winrg", paste0(sample(letters, 10, TRUE), collapse=""))
luxvmrg_name <- paste0("luxrg", paste0(sample(letters, 10, TRUE), collapse=""))
winvmclus_name <- paste0("wincl", paste0(sample(letters, 10, TRUE), collapse=""))
luxvmclus_name <- paste0("luxcl", paste0(sample(letters, 10, TRUE), collapse=""))


test_that("VM creation works",
{
    expect_is(sub$create_vm(winvm_name, location="australiaeast",
              username="ds", pass="PassWord343!"),
        "az_vm_template")
    expect_true(sub$resource_group_exists(winvm_name))

    expect_is(sub$create_vm(luxvm_name, location="australiaeast",
              os="Ubuntu", username="ds", pass=readLines("~/.ssh/id_rsa.pub"), userauth_type="key"),
        "az_vm_template")
    expect_true(sub$resource_group_exists(luxvm_name))

    rg <- sub$create_resource_group(rgname, location="australiaeast")

    expect_is(rg$create_vm(winvmrg_name,
              username="ds", pass="PassWord343!"),
        "az_vm_template")
    expect_is(rg$create_vm(luxvmrg_name,
              os="Ubuntu", username="ds", pass=readLines("~/.ssh/id_rsa.pub"), userauth_type="key"),
        "az_vm_template")
})

test_that("VM interaction works",
{
    winvm <- sub$get_vm(winvm_name)
    expect_is(winvm, "az_vm_template")

    expect_silent(winvm$run_script("dir \\"))

    winvm$stop(deallocate=FALSE, wait=TRUE)
    expect_true(winvm$status[[1]]["PowerState"] == "stopped")

    winvm$resize("Standard_DS2_v2", wait=TRUE)
    expect_true(winvm$.__enclos_env__$private$vm[[1]]$properties$hardwareProfile == "Standard_DS2_v2")

    winvm$start(wait=TRUE)
    expect_true(winvm$status[[1]]["PowerState"] == "running")

    luxvm <- sub$get_vm(luxvm_name)
    expect_is(luxvm, "az_vm_template")

    expect_silent(luxvm$run_script("ls -al /"))

    luxvm$stop(deallocate=FALSE, wait=TRUE)
    expect_true(luxvm$status[[1]]["PowerState"] == "stopped")

    luxvm$resize("Standard_DS2_v2", wait=TRUE)
    expect_true(luxvm$.__enclos_env__$private$vm[[1]]$properties$hardwareProfile == "Standard_DS2_v2")

    luxvm$start(wait=TRUE)
    expect_true(luxvm$status[[1]]["PowerState"] == "running")
})

test_that("VM deletion works",
{
    verify_rg_deleted <- function(rgname)
    {
        for(i in 1:100)
        {
            Sys.sleep(5)
            if(!sub$resource_group_exists(rgname))
                break
        }
        expect_false(sub$resource_group_exists(rgname))
    }

    winvm <- sub$get_vm(winvm_name)
    expect_is(winvm, "az_vm_template")
    winvm$delete(confirm=FALSE)
    verify_rg_deleted(winvm_name)

    luxvm <- sub$get_vm(luxvm_name)
    expect_is(luxvm, "az_vm_template")
    luxvm$delete(confirm=FALSE)
    verify_rg_deleted(luxvm_name)

    rg <- sub$get_resource_group(rgname)

    winvmrg <- rg$get_vm(winvmrg_name)
    expect_is(winvmrg, "az_vm_template")
    winvmrg$delete(confirm=FALSE)

    luxvmrg <- rg$get_vm(luxvmrg_name)
    expect_is(luxvmrg, "az_vm_template")
    luxvmrg$delete(confirm=FALSE)

    Sys.sleep(10)
    expect_true(is_empty(rg$list_resources()))
})


sub$delete_resource_group(rgname, confirm=FALSE)

