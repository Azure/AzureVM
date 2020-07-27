make_name <- function(n=10)
{
    paste(sample(letters, n, TRUE), collapse="")
}

config_tester <- function(img_list, cluster, user, size)
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
