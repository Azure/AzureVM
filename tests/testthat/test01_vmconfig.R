context("VM+scaleset config")


test_that("VM config works",
{
    key_user <- user_config("username", ssh="random key")
    pwd_user <- user_config("username", password="random password")
    img <- image_config(publisher="pubname", offer="offname", sku="skuname")
    vm <- vm_config(img, keylogin=TRUE)
    expect_is(vm, "vm_config")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- ubuntu_18.04()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "Canonical" &&
                vm$image$offer == "UbuntuServer" &&
                vm$image$sku == "18.04-LTS")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- ubuntu_16.04()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "Canonical" &&
                vm$image$offer == "UbuntuServer" &&
                vm$image$sku == "16.04-LTS")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- windows_2019()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "MicrosoftWindowsServer" &&
                vm$image$offer == "WindowsServer" &&
                vm$image$sku == "2019-Datacenter")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", pwd_user, "size"))

    vm <- windows_2016()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "MicrosoftWindowsServer" &&
                vm$image$offer == "WindowsServer" &&
                vm$image$sku == "2016-Datacenter")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", pwd_user, "size"))

    vm <- rhel_8()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "RedHat" &&
                vm$image$offer == "RHEL" &&
                vm$image$sku == "8")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- rhel_7.6()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "RedHat" &&
                vm$image$offer == "RHEL" &&
                vm$image$sku == "7-RAW")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- centos_7.5()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "OpenLogic" &&
                vm$image$offer == "CentOS" &&
                vm$image$sku == "7.5")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- centos_7.6()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "OpenLogic" &&
                vm$image$offer == "CentOS" &&
                vm$image$sku == "7.6")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- debian_8_backports()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "Credativ" &&
                vm$image$offer == "Debian" &&
                vm$image$sku == "8-backports")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- debian_9_backports()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "Credativ" &&
                vm$image$offer == "Debian" &&
                vm$image$sku == "9-backports")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- ubuntu_dsvm()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "microsoft-dsvm" &&
                vm$image$offer == "linux-data-science-vm-ubuntu" &&
                vm$image$sku == "linuxdsvmubuntu")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size"))

    vm <- windows_dsvm()
    expect_is(vm, "vm_config")
    expect_true(vm$image$publisher == "microsoft-dsvm" &&
                vm$image$offer == "dsvm-windows" &&
                vm$image$sku == "server-2016")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", pwd_user, "size"))
})


test_that("VM scaleset config works",
{
    key_user <- user_config("username", ssh="random key")
    pwd_user <- user_config("username", password="random password")
    img <- image_config(publisher="pubname", offer="offname", sku="skuname")
    vm <- vmss_config(img, keylogin=TRUE)
    expect_is(vm, "vmss_config")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- ubuntu_18.04_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "Canonical" &&
                vm$image$offer == "UbuntuServer" &&
                vm$image$sku == "18.04-LTS")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- ubuntu_16.04_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "Canonical" &&
                vm$image$offer == "UbuntuServer" &&
                vm$image$sku == "16.04-LTS")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- windows_2019_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "MicrosoftWindowsServer" &&
                vm$image$offer == "WindowsServer" &&
                vm$image$sku == "2019-Datacenter")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", pwd_user, "size", 5))

    vm <- windows_2016_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "MicrosoftWindowsServer" &&
                vm$image$offer == "WindowsServer" &&
                vm$image$sku == "2016-Datacenter")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", pwd_user, "size", 5))

    vm <- rhel_8_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "RedHat" &&
                vm$image$offer == "RHEL" &&
                vm$image$sku == "8")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- rhel_7.6_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "RedHat" &&
                vm$image$offer == "RHEL" &&
                vm$image$sku == "7-RAW")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- centos_7.5_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "OpenLogic" &&
                vm$image$offer == "CentOS" &&
                vm$image$sku == "7.5")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- centos_7.6_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "OpenLogic" &&
                vm$image$offer == "CentOS" &&
                vm$image$sku == "7.6")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- debian_8_backports_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "Credativ" &&
                vm$image$offer == "Debian" &&
                vm$image$sku == "8-backports")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- debian_9_backports_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "Credativ" &&
                vm$image$offer == "Debian" &&
                vm$image$sku == "9-backports")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- ubuntu_dsvm_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "microsoft-dsvm" &&
                vm$image$offer == "linux-data-science-vm-ubuntu" &&
                vm$image$sku == "linuxdsvmubuntu")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", key_user, "size", 5))

    vm <- windows_dsvm_ss()
    expect_is(vm, "vmss_config")
    expect_true(vm$image$publisher == "microsoft-dsvm" &&
                vm$image$offer == "dsvm-windows" &&
                vm$image$sku == "server-2016")
    expect_silent(build_template_definition(vm))
    expect_silent(build_template_parameters(vm, "vmname", pwd_user, "size", 5))
})

