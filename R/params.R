param_mappings <- list()

param_mappings$win2016_dsvm <- c(
    username="adminUsername",
    passkey="adminPassword",
    name="vmName",
    size="vmSize"
)

param_mappings$win2016_dsvm_cl_ext <- c(
    username="adminUsername",
    passkey="adminPassword",
    name="vmName",
    size="vmSize",
    clust_size="numberOfInstances",
    ext_file_uris="fileUris",
    inst_command="commandToExecute"
)

param_mappings$ubuntu_dsvm <- c(
    username="adminUsername",
    passkey="adminPassword",
    name="vmName",
    size="vmSize"
)

param_mappings$ubuntu_dsvm_key <- c(
    username="adminUsername",
    passkey="sshKeyData",
    name="vmName",
    size="vmSize"
)

param_mappings$ubuntu_dsvm_ext <- c(
    username="adminUsername",
    passkey="adminPassword",
    name="vmName",
    size="vmSize",
    ext_file_uris="fileUris",
    inst_command="commandToExecute",
    command_parm="commandParameter"
)

param_mappings$ubuntu_dsvm_cl <- c(
    username="adminUsername",
    passkey="adminPassword",
    name="vmName",
    size="vmSize",
    clust_size="numberOfInstances"
)

param_mappings$ubuntu_dsvm_cl_key <- c(
    username="adminUsername",
    passkey="sshKeyData",
    name="vmName",
    size="vmSize",
    clust_size="numberOfInstances"
)

param_mappings$ubuntu_dsvm_cl_ext <- c(
    username="adminUsername",
    passkey="adminPassword",
    name="vmName",
    size="vmSize",
    clust_size="numberOfInstances",
    ext_file_uris="fileUris",
    inst_command="commandToExecute"
)
