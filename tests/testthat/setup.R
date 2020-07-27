make_name <- function(n=10)
{
    paste(sample(letters, n, TRUE), collapse="")
}

config_unit_tester <- function(img_list, user)
{
    Map(function(config, arglist)
    {
        vmconf <- get(config)
        vm <- vmconf()
        expect_is(vm, "vm_config")
        expect_identical(vm$image$publisher, arglist[[1]])
        expect_identical(vm$image$offer, arglist[[2]])
        expect_identical(vm$image$sku, arglist[[3]])
        expect_silent(build_template_definition(vm))
        expect_silent(build_template_parameters(vm, "vmname", user, "size"))

        vmssconf <- get(paste0(config, "_ss"))
        vmss <- vmssconf()
        expect_is(vmss, "vmss_config")
        expect_identical(vmss$image$publisher, arglist[[1]])
        expect_identical(vmss$image$offer, arglist[[2]])
        expect_identical(vmss$image$sku, arglist[[3]])
        expect_silent(build_template_definition(vmss))
        expect_silent(build_template_parameters(vmss, "vmname", user, "size", 5))
    }, names(img_list), img_list)
}

config_integration_tester <- function(img_list, cluster, user, size)
{
    vmconfigs <- Map(function(config, arglist) get(config)(),
                     names(img_list), img_list)
    vmssconfigs <- Map(function(config, arglist) get(paste0(config, "_ss"))(),
                       names(img_list), img_list)
    configs <- c(vmconfigs, vmssconfigs)

    testres <- parallel::parLapply(cluster, configs, function(config)
    {
        library(AzureVM)
        vm_name <- make_name(8) # can't be >9 for Windows scaleset
        if(inherits(config, "vm_config"))
            try(rg$create_vm(vm_name, user, size=size, config=config))
        else try(rg$create_vm_scaleset(vm_name, user, size=size, config=config, instances=1))
    })
    lapply(testres, function(result)
    {
        if(inherits(result, "try-error"))
            print(attr(result, "condition"))
        expect_is(result, "az_template")
    })
}
