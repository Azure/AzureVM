context("Resource configs")


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
    expect_null(disk$vm_spec$storageAccountType)
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

    nsg <- nsg_config(list(nsg_rule_allow_ssh))
    expect_is(nsg, "nsg_config")
    expect_is(nsg$properties$securityRules[[1]], "nsg_rule")
    expect_identical(nsg$properties$securityRules[[1]]$name, "Allow-ssh")
})

test_that("Public IP address config works",
{
    ip <- ip_config()
    expect_is(ip, "ip_config")
    expect_null(ip$type)
    expect_null(ip$dynamic)

    ip <- ip_config("static", FALSE)
    expect_is(ip, "ip_config")
    res <- build_resource_fields(ip)
    expect_identical(res$properties,
        list(
            publicIPAllocationMethod="static",
            publicIPAddressVersion="IPv4",
            dnsSettings=list(domainNameLabel="[parameters('vmName')]")
        )
    )
    expect_identical(res$sku,
        list(name="static")
    )
})

test_that("Virtual network config works",
{
    vnet <- vnet_config()
    expect_is(vnet, "vnet_config")
    expect_is(vnet$properties$subnets[[1]], "subnet_config")

    res <- build_resource_fields(vnet)
    expect_identical(res$properties,
        list(
            addressSpace=list(addressPrefixes=I("10.0.0.0/16")),
            subnets=list(
                list(
                    name="subnet",
                    properties=list(
                        addressPrefix="10.0.0.0/16",
                        networkSecurityGroup=list(id="[variables('nsgId')]")
                    )
                )
            )
        )
    )
})

test_that("Network interface config works",
{
    nic <- nic_config()
    expect_is(nic, "nic_config")

    res <- build_resource_fields(nic)
    expect_identical(res$properties,
        list(
            ipConfigurations=list(
                list(
                    name="ipconfig",
                    properties=list(
                        privateIPAllocationMethod="dynamic",
                        subnet=list(id="[variables('subnetId')]"),
                        publicIPAddress=list(id="[variables('ipId')]")
                    )
                )
            )
        )
    )
})

test_that("Load balancer config works",
{
    lb <- lb_config()
    expect_is(lb, "lb_config")
    expect_null(lb$type)

    lb <- lb_config(type="basic")
    res <- build_resource_fields(lb)
    expect_identical(res$properties,
        list(
            frontendIPConfigurations=list(
                list(
                    name="[variables('lbFrontendName')]",
                    properties=list(
                        publicIPAddress=list(id="[variables('ipId')]")
                    )
                )
            ),
            backendAddressPools=list(
                list(
                    name="[variables('lbBackendName')]"
                )
            ),
            loadBalancingRules=list(),
            probes=list()
        )
    )
    expect_identical(res$sku,
        list(name="basic")
    )

    lb <- lb_config(type="basic", rules=list(lb_rule_ssh), probes=list(lb_probe_ssh))
    expect_is(lb$rules[[1]], "lb_rule")
    expect_is(lb$probes[[1]], "lb_probe")
    res <- build_resource_fields(lb)
    expect_identical(res$properties$loadBalancingRules[[1]], unclass(lb_rule_ssh))
    expect_identical(res$properties$probes[[1]], unclass(lb_probe_ssh))
})

test_that("Autoscaler config works",
{
    as <- autoscaler_config()
    expect_is(as, "as_config")
    expect_is(as$properties$profiles[[1]], "as_profile_config")

    res <- build_resource_fields(as)
    expect_identical(res$properties,
        list(
            name="[variables('asName')]",
            targetResourceUri="[variables('vmId')]",
            enabled=TRUE,
            profiles=list(
                unclass(autoscaler_profile())
            )
        )
    )
})
