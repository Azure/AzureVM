lapply(list.files("tpl", pattern="\\.json$"), function(f)
{
    obj <- sub("\\.json$", "", f)
    assign(obj, jsonlite::fromJSON(file.path("tpl", f), simplifyVector=FALSE), parent.env(environment()))
})

class(nsg_rule_allow_ssh) <- class(nsg_rule_allow_jupyter) <-
    class(nsg_rule_allow_rstudio) <- class(nsg_rule_allow_rdp) <- "nsg_rule_config"
