lapply(dir("inst/tpl", pattern="\\.json$"), function(f)
{
    objname <- sub("\\.json$", "", f)
    obj <- jsonlite::fromJSON(file.path("inst/tpl", f), simplifyVector=FALSE)

    assign(objname, obj, parent.env(environment()))
})

