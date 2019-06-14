# from AzureRMR
get_paged_list <- function(lst, token, next_link_name="nextLink", value_name="value")
{
    res <- lst[[value_name]]
    while(!is_empty(lst[[next_link_name]]))
    {
        lst <- call_azure_url(token, lst[[next_link_name]])
        res <- c(res, lst[[value_name]])
    }
    res
}

