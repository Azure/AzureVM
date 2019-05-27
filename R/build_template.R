build_linuxdsvm_template <- function()
{}

build_windowsdsvm_template <- function()
{}

build_win2019_template <- function()
{}

build_win2016_template <- function()
{}

build_ubuntu1804_template <- function()
{}

build_ubuntu1604_template <- function()
{}

build_aml_template <- function()
{}


build_template <- function(parameters=list(), variables=list(), outputs=list(), nsrules=list(), 
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

    list(
        `$schema`="https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        contentVersion="1.0.0.0",
        parameters=parameters,
        variables=variables,
        resources=list(nic, nsg, vnet, ip, vm),
        outputs=outputs
    )
}


