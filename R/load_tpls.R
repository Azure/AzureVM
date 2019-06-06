lapply(dir("inst/tpl", pattern="\\.json$"), function(f)
{
    objname <- sub("\\.json$", "", f)
    obj <- jsonlite::fromJSON(file.path("inst/tpl", f), simplifyVector=FALSE)

    if(grepl("nsg_rule", objname, fixed=TRUE))
        class(obj) <- "nsg_rule_config"

    assign(objname, obj, parent.env(environment()))
})

