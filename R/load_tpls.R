#' @export
tpl_env <- new.env()

for(f in list.files("tpl", pattern="\\.json$"))
{
    objname <- sub("\\.json$", "", f)
    obj <- jsonlite::fromJSON(file.path("tpl", f), simplifyVector=FALSE)

    if(grepl("nsg_rule", objname, fixed=TRUE))
        class(obj) <- "nsg_rule_config"

    assign(objname, obj, tpl_env)
}
