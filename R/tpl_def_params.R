os_key_login <- jsonlite::fromJSON(
    '{
        "properties": {
            "osProfile": {
                "linuxConfiguration": {
                    "disablePasswordAuthentication": true,
                    "ssh": {
                        "publicKeys": [
                            {
                                "path": "[concat(\'/home/\', parameters(\'adminUsername\'), \'/.ssh/authorized_keys\')]",
                                "keyData": "[parameters(\'sshKeyData\')]"
                            }
                        ]
                    }
                }
            }
        }
    }',
    simplifyVector=FALSE
)


os_pwd_login <- jsonlite::fromJSON(
    '{
        "properties": {
            "osProfile": {
                "adminPassword": "[parameters(\'adminPassword\')]"
            }
        }
    }',
    simplifyVector=FALSE
)


nsrule_allow_ssh <- jsonlite::fromJSON(
    '{
        "name": "Allow-SSH",
        "properties": {
            "protocol": "Tcp",
            "access": "Allow",
            "priority": 100,
            "direction": "Inbound",
            "destinationPortRange": "22"
        }
    }',
    simplifyVector=FALSE
)


nsrule_allow_jupyter <- jsonlite::fromJSON(
    '{
        "name": "Allow-JupyterHub",
        "properties": {
            "protocol": "Tcp",
            "access": "Allow",
            "priority": 101,
            "direction": "Inbound",
            "destinationPortRange": "8000"
        }
    }',
    simplifyVector=FALSE
)


nsrule_allow_rdp <- jsonlite::fromJSON(
    '{
        "name": "Allow-RDP",
        "properties": {
            "protocol": "Tcp",
            "access": "Allow",
            "priority": 102,
            "direction": "Inbound",
            "destinationPortRange": "3389"
        }
    }',
    simplifyVector=FALSE
)


nsrule_allow_rstudio <- jsonlite::fromJSON(
    '{
        "name": "Allow-RStudio-Server",
        "properties": {
            "protocol": "Tcp",
            "access": "Allow",
            "priority": 103,
            "direction": "Inbound",
            "destinationPortRange": "8787"
        }
    }',
    simplifyVector=FALSE
)


dsvm_datadisk_0 <- jsonlite::fromJSON(
    '{
        "name": "[variables(\'DataDiskName\')]",
        "managedDisk": {
            "storageAccountType": "Standard_LRS"
        },
        "createOption": "FromImage",
        "lun": 0
    }',
    simplifyVector=FALSE
)

