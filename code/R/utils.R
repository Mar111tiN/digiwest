library(yaml)


##### this is a function-specific config wrapper that
# 1) translates the arguments from a config yaml into a list
# 2) updates the arguments in the config list with directly passed arguments from the ellipsis
# ....c(list1, list2) updates duplicate entries with data from list2
# 3) creates pop.levels and pop.colors from the pops list
# 4) finally it calls the combined plot function with do.call and the list of arguments
### usually you might just need the simple yaml read and args <- list(...) but for nested and more complex configs
# you will have to add some extra logic
# source(file.path(R_path, "stat.R"))
source(file.path(R_path, "plot_constants.R"))
source(file.path(R_path, "plot_heatmap.R"))

digi_wrapper <- function(config_file="",  ...) {
    config <- read_yaml(config_file)
    plot_configs <- config$plot_heatmap

    # create a few paths from config$path and load data
    tables_path <- file.path(Sys.getenv("HOME"), config$paths$base_path, config$paths$tables_path)
    output_img_path <- file.path(Sys.getenv("HOME"), config$paths$base_path, config$paths$img_path)

    # convert the list_style configs to vector    
    plot_configs$figsize <- as_vector(plot_configs$figsize)
    plot_configs$row_info <- as_vector(plot_configs$row_info)
    plot_configs$col_info <- as_vector(plot_configs$col_info)
    plot_configs$show_stims <- as_vector(plot_configs$show_stims)
    plot_configs$show_cytos <- as_vector(plot_configs$show_cytos)
    # update with the direct args
    args <- list(...)
    plot_configs <- modifyList(plot_configs, args)

    
    # build the IO files
    if (!startsWith(plot_configs$table_file, "/")) {
        plot_configs$table_file <- file.path(tables_path, plot_configs$table_file)
    }    

    if (plot_configs$plot_file != "") {
        if (!startsWith(plot_configs$plot_file, "/")) {
            plot_configs$plot_file <- file.path(output_img_path, plot_configs$plot_file)
        }
    }
    # # build the plot_file_base and add to configs
    # if (!startsWith(plot_configs$plot_file_base, "/")) {
    #     plot_configs$plot_file_base <- file.path(plot_configs$results_folder, "Rimg", plot_configs$plot_file_base)
    # }

    do.call(digi_heatmap, plot_configs)
}