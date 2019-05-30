lapply(list.files("tpl", pattern="\\.json$"), function(f)
{
    obj <- sub("\\.json$", "", f)
    assign(obj, jsonlite::fromJSON(file.path("tpl", f), simplifyVector=FALSE), parent.env(environment()))
})
