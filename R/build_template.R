build_datadisk_array <- function(n)
{
    lapply(seq_len(n), function(i)
    {
        disk <- blank_datadisk
        disk$name <- sprintf("[concat(parameters(\'vmName\'), \'-data-%s\')]", i)
        disk
    })
}


build_template_internal <- function(parameters=list(), variables=list(), outputs=list(),
                                    nsrules=list(), datadisks=list(),
                                    nic=list(), nsg=list(), vnet=list(), ip=list(), vm=list())
{
    parameters <- modifyList(tpl_parameters_default, parameters)
    variables <- modifyList(tpl_variables_default, variables)
    outputs <- modifyList(tpl_outputs_default, outputs)

    nic <- modifyList(nic_default, nic)
    nsg <- modifyList(nsg_default, nsg)
    vnet <- modifyList(vnet_default, vnet)
    ip <- modifyList(ip_default, ip)
    vm <- modifyList(vm_default, vm)

    nsg$properties$securityRules <- nsrules

    for(i in seq_along(datadisks))
        datadisks[[i]]$lun <- i - 1

    if(!is_empty(datadisks))
        vm$properties$storageProfile$datadisks <- datadisks

    list(
        `$schema`="https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        contentVersion="1.0.0.0",
        parameters=parameters,
        variables=variables,
        resources=list(nic, nsg, vnet, ip, vm),
        outputs=outputs
    )
}


