#### plot_heatmap.R does everything needed for the plot functionality:

# loads its own dependencies
library(tidyverse)
library(patchwork)
library(pheatmap)
library(viridis)
library(RColorBrewer)
# source(file.path(R_path, "stat.R"))
source(file.path(R_path, "plot_constants.R"))


######## FUNC :: LOAD DATA ###############
# load the map with appropriate filtering
filter_data <- function(
  #  filter function should also remove
  #  WO in case of wo columns
  #  WO, IL-2 and CXCL9/10 in case of CXCL.. columns
  df, 
  max_NA=1, 
  show_phospho_only=FALSE, 
  show_extra_peak=FALSE,
  ...
  ) { # nolint
    data <- df %>%
     # set the max fraction of 33 (NA) values
        filter(NAvalues < max_NA)
    if (show_phospho_only) {
        data <- data %>%
            # only include phosphorylated
            filter(!is.na(Phospho))
        }
    if (!show_extra_peak) {
        data <- data %>% 
            # filter only Peak1
            filter(Peak == 1)
    }
    return(data)
}


df2mat <- function(df, data_col="logMFI_sc") {
  df %>%
    select(c(Sample, Pop, Stim, Cyto, Analyte, all_of(data_col))) %>%
    pivot_wider(names_from = Analyte, values_from = all_of(data_col)) %>% # nolint
    column_to_rownames(var = "Sample") %>%
    as.matrix() %>%
    t()
}

######## FUNC :: CREATE HEATMAP ###############
plot_digi_heatmap <- function(
    # maybe get rid of defaults here
    dff,
    data_col = "logMFI_sc_minWO",
    # provide defaults
    cutree_rows = 3,
    cutree_cols = 3,
    treeheight_row = 17,
    treeheight_col = 17,
    show_colnames=F,
    row_info = c("Phospho", "Peak"),
    col_info = c("Cyto", "Pop", "Stim"),
    show_stims=c("unstim", "stim"),
    show_cytos=c("IL-2", "wo", "CXCL9", "CXCL10", "CXCL11"),
    heat_color = "heat",
    anno_colors = sarah_colors,
    show_phospho_only=TRUE,
    show_extra_peak=FALSE,
    show_data = list(
        Pop = c(),
        Stim = c(),
        Cyto = c()
        ),
    hide_data = c(
        list(Stim = "unstim", Cyto = "wo")
        ),
    ...
  ) {
    # reset the output
    while (!is.null(dev.list()))  dev.off()
  #########################################
    # filter for show_data entries
    for (data in names(show_data)) {
        # select for the filtered columns
        dff <- dff %>% 
            filter(.data[[data]] %in% show_data[[data]]) %>%
            mutate({{data}} := factor(.data[[data]], levels = show_data[[data]]))
        # reduce color annotations to filtered values
        anno_colors[[data]] <- anno_colors[[data]][intersect(names(anno_colors[[data]]), show_data[[data]])]
    }
    # negatively filter for the hide_data items
    for (hide_item in hide_data) {
        # build the list of filter expressions for each data of this hidden item
        filter_exprs <- c()
        for (data in names(hide_item)) {
            filter_exprs <- c(filter_exprs, str_glue("{data} == '{hide_item[[data]]}'"))
        }
        filter_expr_pre <- paste(filter_exprs, collapse = ' & ')
        filter_expr <- str_glue("!({filter_expr_pre})")

        # evaluate the filter_expr in the filter
        dff <- dff %>% filter(rlang::eval_tidy(rlang::parse_expr(filter_expr)))
    }

    # get the annotations into a dataframe
    # extract the row.info
    if (show_phospho_only & !show_extra_peak) {
        # do not show any row info
        row.info=NA
    } else {
        # remove Phospho from row_info fields
        if (show_phospho_only) {
            row_info <- setdiff(row_info, c("Phospho"))
        }
        # remove Peak from row_info fieldsf
        if (!show_extra_peak) {
            row_info <- setdiff(row_info, c("Peak"))
        }

        row.info <- dff %>% 
            select(c(Analyte, all_of(row_info))) %>% 
            unique() %>% 
            column_to_rownames(var = "Analyte")
        if ("Phospho" %in% all_of(row_info)) {
            row.info <- row.info %>% 
                mutate(Phospho = as.factor(as.numeric(!is.na(Phospho))))
        }
        if ("Peak" %in% all_of(row_info)) {
                row.info <- row.info %>% 
                mutate(Peak = as.factor(Peak))
        }
    }

    ### HARDCODED SORT
    # dff <- dff %>%
    #     arrange(Cells, Treatment, Donor)
    # if
    # extract the col.info
    col.info <- dff %>% 
      select(c(Sample, all_of(col_info))) %>% 
      unique() %>% 
      column_to_rownames(var = "Sample") %>% 
      data.frame()


    # turn into function
    heat.mat <- dff %>%
      select(c(Sample, Analyte, all_of(data_col))) %>%
      pivot_wider(names_from = Analyte, values_from = all_of(data_col)) %>% # nolint
      column_to_rownames(var = "Sample") %>%
      as.matrix() %>%
      t()

    ##### SET THE COLORS ############
    if (heat_color == "heat") {
        heat_color <- colorRampPalette(rev(brewer.pal(n = 7, name ="RdYlBu")))(100)
    } else {
        if (heat_color == "magma") {
            heat_color <- viridis(n = 256, alpha = 1, option = "magma")
        }
    }

    # print(heat.mat)
      # call the heatmap function
    heat.map <- heat.mat %>%
      pheatmap(
        color = heat_color,
        annotation_row = row.info,
        annotation_col = col.info,
        annotation_colors = anno_colors,
        # passing defaults
        cutree_rows = cutree_rows,
        cutree_cols = cutree_cols,
        treeheight_row = treeheight_row,
        treeheight_col = treeheight_col,
        show_colnames = show_colnames,
        ...
      )
    return(heat.map)
}



digi_heatmap <- function(
    # load-plot-save combine function
    table_file = "",
    plot_file = "",
    figsize = c(7, 7),
    plot_type = "png",
    ...
) {
    ## load the df
    df <- read_tsv(table_file)

    # filter the data
    dff <- filter_data(df, ...)
    # plot and print the data
    if (plot_file == "") {
        plot_file <- NA
        width <- NA
        height <- NA
    } else {
        # create the 
        if (!endsWith(plot_file, str_glue(".{plot_type}"))) {
            plot_file <- str_glue("{plot_file}.{plot_type}")
        }
        width <- figsize[[1]]
        height <- figsize[[2]]
    }
    plot <- plot_digi_heatmap(
        dff,
        filename=plot_file,
        width=width,
        height=height,
        ...
    )

    return(plot)
}