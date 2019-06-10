az_vmss_resource <- R6::R6Class("az_vmss_resource", inherit=AzureRMR::az_resource,

public=list(
    status=NULL
))
