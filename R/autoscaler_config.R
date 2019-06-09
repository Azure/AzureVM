autoscaler_config <- function(profiles=list(autoscaler_profile()), ...)
{
    props <- list(profiles=profiles, ...)
    structure(list(properties=props), class="as_config")
}


build_resource_fields.as_config <- function(object, ...)
{
    object$properties$profiles <- lapply(object$properties$profiles, unclass)
    utils::modifyList(as_default, object)
}


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
