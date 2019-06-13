#' Autoscaler configuration
#'
#' @param profiles A list of autoscaling profiles, each obtained via a call to `autoscaler_profile`.
#' @param ... Other named arguments that will be treated as resource properties.
#' @param name For `autoscaler_profile`, a name for the profile.
#' @param minsize,maxsize,default For `autoscaler_profile`, the minimum, maximum and default number of instances.
#' @param scale_out,scale_in For `autoscaler_profile`, the percentage CPU at which to scale out and in, respectively.
#' @param interval For `autoscaler_profile`, The interval between samples, in ISO 8601 format. The default is 1 minute.
#' @param window For `autoscaler_profile`, the window width over which to compute the percentage CPU. The default is 5 minutes.
#'
#' @seealso
#' [create_vm_scaleset], [vmss_config]
#' @export
autoscaler_config <- function(profiles=list(autoscaler_profile()), ...)
{
    props <- list(profiles=profiles, ...)
    structure(list(properties=props), class="as_config")
}


build_resource_fields.as_config <- function(config, ...)
{
    config$properties$profiles <- lapply(config$properties$profiles, unclass)
    utils::modifyList(as_default, config)
}


add_template_variables.as_config <- function(config, ...)
{
    name <- "[concat(parameters('vmName'), '-as')]"
    id <- "[resourceId('Microsoft.Insights/autoscaleSettings', variables('asName'))]"
    ref <- "[concat('Microsoft.Insights/autoscaleSettings/', variables('asName'))]"
    capacity <- "[mul(int(parameters('instanceCount')), 10)]"
    scaleval <- "[max(div(int(parameters('instanceCount')), 5), 1)]"
    list(asName=name, asId=id, asRef=ref, asMaxCapacity=capacity, asScaleValue=scaleval)
}


#' @rdname autoscaler_config
#' @export
autoscaler_profile <- function(name="Profile", minsize=1, maxsize=NA, default=NA, scale_out=0.75, scale_in=0.25,
                               interval="PT1M", window="PT5M")
{
    if(is.na(maxsize))
        maxsize <- "[variables('asMaxCapacity')]"
    if(is.na(default))
        default <- "[parameters('instanceCount')]"
    capacity <- list(minimum=minsize, maximum=maxsize, default=default)

    trigger <- list(
        metricName="Percentage CPU",
        metricNamespace="",
        metricResourceUri="[variables('vmId')]",
        timeGrain=interval,
        timeWindow=window,
        statistic="Average",
        timeAggregation="Average"
    )
    action <- list(
        type="ChangeCount",
        value="[variables('asScaleValue')]",
        cooldown=interval
    )

    rule_out <- list(metricTrigger=trigger, scaleAction=action)
    rule_out$metricTrigger$operator <- "GreaterThan"
    rule_out$metricTrigger$threshold <- round(scale_out * 100)
    rule_out$scaleAction$direction <- "Increase"

    rule_in <- list(metricTrigger=trigger, scaleAction=action)
    rule_in$metricTrigger$operator <- "LessThan"
    rule_in$metricTrigger$threshold <- round(scale_in * 100)
    rule_in$scaleAction$direction <- "Decrease"

    prof <- list(
        name=name,
        capacity=capacity,
        rules=list(rule_out, rule_in)
    )
    structure(prof, class="as_profile_config")
}
