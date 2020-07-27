context("VM+scaleset config")

key_user <- user_config("username", ssh="random key")

test_that("VM config works",
{
    img <- image_config(publisher="pubname", offer="offname", sku="skuname")
    vm <- vm_config(img, keylogin=TRUE)
    expect_is(vm, "vm_config")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))
})


test_that("VM scaleset config works",
{
    img <- image_config(publisher="pubname", offer="offname", sku="skuname")
    vm <- vmss_config(img, keylogin=TRUE)
    expect_is(vm, "vmss_config")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))
})

