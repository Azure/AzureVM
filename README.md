# AzureVM

This is a package for interacting with virtual machines in Azure. You can deploy, start up, shut down, run scripts, deallocate and delete VMs from the R command line. A number of VM templates are included based on the [Data Science Virtual Machine](https://azure.microsoft.com/en-us/services/virtual-machines/data-science-virtual-machines/), but you can also deploy other templates that you supply.

AzureVM uses the tools provided by the [AzureRMR package](https://github.com/hong-revo/AzureRMR) to manage VM resources and templates. The main VM R6 class wraps the deployment template, allowing easy management of all resources as a unit. You can also create a VM in exclusive mode, meaning that it sits in its own resource group.

The package supports both single VMs as well as clusters. A single VM is treated as a cluster containing only one node.

A sample workflow:

```r
library(AzureRMR)
library(AzureVM)

# authenticate with Resource Manager
az <- az_rm$new(tenant="xxx-xxx-xxx", app="yyy-yyy-yyy", secret="{secret goes here}")

sub1 <- az$get_subscription("5710aa44-281f-49fe-bfa6-69e66bb55b11")

# list VM sizes -- a large data frame
sub1$list_vm_sizes(location="australiasoutheast")
#         name numberOfCores osDiskSizeInMB resourceDiskSizeInMB memoryInMB maxDataDiskCount
# 1 Standard_A0             1        1047552                20480        768                1
# 2 Standard_A1             1        1047552                71680       1792                2
# 3 Standard_A2             2        1047552               138240       3584                4
# 4 Standard_A3             4        1047552               291840       7168                8
# 5 Standard_A5             2        1047552               138240      14336                4
# 6 Standard_A4             8        1047552               619520      14336               16
# ...

# create a new Ubuntu VM in an existing resource group
rg <- sub1$get_resource_group("rdev1")
key <- readLines("~/id_rsa.pub")
rdevtest <- rg$create_vm("rdevtest", username="user", passkey=key, userauth_type="key", os="Ubuntu",
                         location="australiasoutheast")
rdevtest
#<Azure virtual machine rdevtest>
#  Operating system: Linux 
#  Exclusive resource group: FALSE
#  Domain name: rdevtest.australiasoutheast.cloudapp.azure.com
#  Status:
#             ProvisioningState PowerState
#    rdevtest         succeeded    running
#---
#  disks: list(rdevtest)
#  id: /subscriptions/5710aa44-281f-49fe-bfa6-69e66bb55b11/resourceGroups/rdev1/providers/Microsoft.Resou ...
#  ip_address: xxx.xxx.xxx.xxx
#  properties: list(templateHash, parameters, mode, debugSetting, provisioningState, timestamp, duration,
#    correlationId, providers, dependencies, outputs, outputResources)
#---
#  Methods:
#    add_extension, cancel, check, delete, restart, run_deployed_command, run_script, start, stop,
#    sync_vm_status

# shut down the VM
rdevtest$stop()

# ... and delete it (this will take some time)
rdevtest$delete()


# calling create_vm() from a subscription object will create the VM in its own resource group
rdevtest2 <- sub1$create_vm("rdevtest2", username="user", passkey=key, userauth_type="key", os="Ubuntu",
                            location="australiasoutheast")

# run a shell script or command remotely (will be PowerShell on a Windows VM)
rdevtest2$run_script("ifconfig > /tmp/ifc.txt")

# ... and stop it
rdevtest2$stop()

# .. and delete it (this can be done asynchronously for a VM in its own group)
rdevtest2$delete()
```

