tpl_parameters_default <- jsonlite::fromJSON(
    '{
        "adminUsername": {
            "type": "string"
        },
        "vmName": {
            "type": "string"
        },
        "vmSize": {
            "type": "string"
        },
        "imagePublisher": {
            "type": "string"
        },
        "imageOffer": {
            "type": "string"
        },
        "vmSku": {
            "type": "string"
        }
    }'
)


tpl_variables_default <- jsonlite::fromJSON(
    '{
        "location": "[resourceGroup().location]",
        "OSDiskName": "[concat(parameters(\'vmName\'), \'-osdisk\')]",
        "DataDiskName0": "[concat(parameters(\'vmName\'), \'-data-0\')]",
        "DataDiskName1": "[concat(parameters(\'vmName\'), \'-data-1\')]",
        "nsgName": "[concat(parameters(\'vmName\'), \'-nsg\')]",
        "nsgId": "[resourceId(\'Microsoft.Network/networkSecurityGroups\', variables(\'nsgName\'))]",
        "nicId": "[resourceId(\'Microsoft.Network/networkInterfaces\', parameters(\'vmName\'))]",
        "ipId": "[resourceId(\'Microsoft.Network/publicIPAddresses\', parameters(\'vmName\'))]",
        "vnetId": "[resourceId(\'Microsoft.Network/virtualNetworks\', parameters(\'vmName\'))]",
        "vmId": "[resourceId(\'Microsoft.Compute/virtualMachines\', variables(\'vmName\'))]",
        "subnet": "Subnet1"
    }',
    simplifyVector=FALSE
)


vm_default <- jsonlite::fromJSON(
    '{
        "apiVersion": "2019-03-01",
        "type": "Microsoft.Compute/virtualMachines",
        "name": "[parameters(\'vmName\')]",
        "location": "[variables(\'location\')]",         
        "tags": {
            "CreatedBy": "AzureR/AzureVM"
        },
        "dependsOn": [
            "[concat(\'Microsoft.Network/networkInterfaces/\', parameters(\'vmName\'))]"
        ],
        "properties": {
            "hardwareProfile": {
                "vmSize": "[parameters(\'vmSize\')]"
            },
            "osProfile": {
                "computerName": "[parameters(\'vmName\')]",
                "adminUsername": "[parameters(\'adminUsername\')]"
            },
            "storageProfile": {
                "imageReference": {
                    "publisher": "[parameters(\'imagePublisher\')]",
                    "offer": "[parameters(\'imageOffer\')]",
                    "sku": "[parameters(\'vmSku\')]",
                    "version": "latest"
                },
                "osDisk": {
                    "name": "[parameters(\'OSDiskName\')]",
                    "managedDisk": {
                        "storageAccountType": "Standard_LRS"           
                    },
                    "createOption": "FromImage"
                }
            },
            "networkProfile": {
                "networkInterfaces": [
                    {
                        "id": "[parameters(\'nicId\')]"
                    }
                ]
            },
            "diagnosticsProfile": {
                "bootDiagnostics": {
                    "enabled": false
                }
            }
        }
    }',
    simplifyVector=FALSE
)


vnet_default <- jsonlite::fromJSON(
    '{
        "apiVersion": "2018-11-01",
        "type": "Microsoft.Network/virtualNetworks",
        "name": "[parameters(\'vmName\')]",
        "location": "[variables(\'location\')]",
        "dependsOn": [
            "[concat(\'Microsoft.Network/networkSecurityGroups/\', variables(\'nsgName\'))]"
        ],
        "properties": {
            "addressSpace": {
                "addressPrefixes": [
                    "10.0.0.0/16"
                ]
            },
            "subnets": [
                {
                    "name": "[variables(\'Subnet\')]",
                    "properties": {
                        "addressPrefix": "10.0.0.0/24"
                    }
                }
            ]
        }
    }',
    simplifyVector=FALSE
)


nic_default <- jsonlite::fromJSON(
    '{
        "apiVersion": "2018-11-01",
        "type": "Microsoft.Network/networkInterfaces",
        "name": "[variables(\'vmName\')]",
        "location": "[variables(\'location\')]",
        "dependsOn": [
            "[concat(\'Microsoft.Network/publicIPAddresses/\', variables(\'vmName\'))]",
            "[concat(\'Microsoft.Network/networkSecurityGroups/\', variables(\'vmName\'))]",
            "[concat(\'Microsoft.Network/virtualNetworks/\', variables(\'vmName\'))]"
        ],
        "properties": {
            "ipConfigurations": [
                {
                    "name": "ipconfig1",
                    "properties": {
                        "privateIPAllocationMethod": "Dynamic",
                        "publicIPAddress": {
                            "id": "[variables(\'ipId\')]"
                        },
                        "subnet": {
                            "id": "[concat(variables(\'vnetId\'), \'/subnets/\', variables(\'Subnet\'))]"
                        }
                    }
                }
            ],
            "networkSecurityGroup": {
                "id": "[variables(\'nsgId\')]"
            }
        }
    }',
    simplifyVector=FALSE
)


ip_default <- NULL

nsg_default <- NULL


tpl_outputs_default <- jsonlite::fromJSON(
    '{
        "vmName": {
            "type": "string",
            "value": "[parameters(\'vmName\')]"
        },
        "adminUsername": {
            "type": "string",
            "value": "[parameters(\'adminUsername\')]"
        }

    }',
    simplifyVector=FALSE
)


template_skeleton <- list(
    `$schema`="https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    contentVersion="1.0.0.0",
    parameters=tpl_parameters_default,
    variables=tpl_variables_default,
    resources=list(nic_default, nsg_default, vnet_default, ip_default, vm_default),
    outputs=tpl_outputs_default
)


