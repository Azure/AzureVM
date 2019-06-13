context("Template builders")


test_that("User config works",
{
    user <- user_config("username", sshkey="random key")
    expect_is(user, "user_config")
    expect_identical(user$key, "random key")

    user <- user_config("username", password="random password")
    expect_is(user, "user_config")
    expect_identical(user$pwd, "random password")

    user <- user_config("username", sshkey="../testthat.R")
    expect_is(user, "user_config")
    expect_identical(user$key, readLines("../testthat.R"))
})

test_that("Datadisk config works",
{
    disk <- datadisk_config(100)
    expect_is(disk, "datadisk_config")
    expect_identical(disk$res_spec$diskSizeGB, 100)
    expect_identical(disk$vm_spec$createOption, "attach")
    expect_identical(disk$vm_spec$caching, "None")
    expect_identical(disk$vm_spec$storageAccountType, NULL)
})

test_that("Image config works",
{
    expect_error(image_config())

    img <- image_config(publisher="pubname", offer="offname", sku="skuname")
    expect_is(img, "image_marketplace")

    img <- image_config(id="resource_id")
    expect_is(img, "image_custom")
})

test_that("Network security group config works",
{
    nsg <- nsg_config()
    expect_is(nsg, "nsg_config")

    expect_identical(build_resource_fields(nsg), nsg_default)
})
