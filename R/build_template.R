build_ubuntudsvm_template <- function(login_user, datadisks)
{
    datadisks <- build_datadisk_array(datadisks)

    build_template_internal(
        variables=unclass(vm_images["ubuntu_dsvm", ]),
        nsrules=list(nsrule_allow_ssh, nsrule_allow_jupyter, nsrule_allow_rstudio),
        datadisks=c(list(ubuntudsvm_datadisk), datadisks),
        vm=if(is_empty(login_user$key)) os_pwd_login else os_key_login
    )
}

build_windsvm_template <- function(login_user, datadisks)
{
    datadisks <- build_datadisk_array(datadisks)

    build_template_internal(
        variables=unclass(vm_images["windows_dsvm", ]),
        nsrules=list(nsrule_allow_rdp),
        datadisks=datadisks,
        vm=os_pwd_login
    )
}

build_win2019_template <- function(login_user, datadisks)
{
    datadisks <- build_datadisk_array(datadisks)

    build_template_internal(
        variables=unclass(vm_images["windows_2019", ]),
        nsrules=list(nsrule_allow_rdp),
        datadisks=datadisks,
        vm=os_pwd_login
    )
}

build_win2016_template <- function(login_user, datadisks)
{
    datadisks <- build_datadisk_array(datadisks)

    build_template_internal(
        variables=unclass(vm_images["windows_2016", ]),
        nsrules=list(nsrule_allow_rdp),
        datadisks=datadisks,
        vm=os_pwd_login
    )
}

build_ubuntu1804_template <- function(login_user, datadisks)
{
    datadisks <- build_datadisk_array(datadisks)

    build_template_internal(
        variables=unclass(vm_images["ubuntu_1804", ]),
        nsrules=list(nsrule_allow_ssh),
        datadisks=datadisks,
        vm=if(is_empty(login_user$key)) os_pwd_login else os_key_login
    )
}

build_ubuntu1604_template <- function(login_user, datadisks)
{
    datadisks <- build_datadisk_array(datadisks)

    build_template_internal(
        variables=unclass(vm_images["ubuntu_1604", ]),
        nsrules=list(nsrule_allow_ssh),
        datadisks=datadisks,
        vm=if(is_empty(login_user$key)) os_pwd_login else os_key_login
    )
}


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


