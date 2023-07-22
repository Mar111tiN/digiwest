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
    df, 
    max_NA=1, 
    show_phospho_only=FALSE, 
    show_extra_peak=FALSE,
    ...
  ) { 
    #  filter function should also remove
    #  WO in case of wo columns
    #  WO, IL-2 and CXCL9/10 in case of CXCL.. columns
    
    # nolint
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

######## FUNC :: CREATE HEATMAP ###############
plot_digi_heatmap <- function(
    # maybe get rid of defaults here
    data,
    title="Digiwest Heatmap",
    data_col = "logMFI_sc_minWO",
    # provide defaults
    row_info = c("Phospho", "Peak"),
    col_info = c("Cyto", "Pop", "Stim"),
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
    filename=NA,
    figsize=c(7, 7),
    factors=list(),
    ...
  ) {

    ############# SPECS ############
    # data is a dataframe

    ############ INIT #############
    while (!is.null(dev.list()))  dev.off()

    ############ FILTER ###########
    # filter the data using the passed args
    dff <- filter_data(data, 
        show_phospho_only, 
        show_extra_peak,
        ...
    )

    # select for the show_data entries
    for (show_col in names(show_data)) {
        dff <- dff %>%                                     
            filter(.data[[show_col]] %in% show_data[[show_col]]) %>%       # filter for show_data entries
            mutate({{show_col}} := factor(.data[[show_col]], levels = show_data[[show_col]]))

        # reduce color annotations to filtered values
        anno_colors[[show_col]] <- anno_colors[[show_col]][intersect(names(anno_colors[[show_col]]), show_data[[show_col]])]
    }

    # negatively filter for the hide_data items
    for (hide_item in hide_data) {
        # build the list of filter expressions for each data of this hidden item
        filter_exprs <- c()
        for (hide_col in names(hide_item)) {
            filter_exprs <- c(filter_exprs, str_glue("({hide_col} == '{hide_item[[hide_col]]}')"))
        }
        filter_expr_pre <- paste(filter_exprs, collapse = ' & ')
        filter_expr <- str_glue("!({filter_expr_pre})")
        # evaluate the filter_expr in the filter
        dff <- dff %>%filter(rlang::eval_tidy(rlang::parse_expr(filter_expr)))
    }

    # get the annotations into a dataframe
    # extract the row.info
    if (show_phospho_only & !show_extra_peak) {
        # do not show any row info
        row_info_df=NA
    } else {
        # remove Phospho from row_info fields
        if (show_phospho_only) {
            row_info <- setdiff(row_info, c("Phospho"))
        }
        # remove Peak from row_info fieldsf
        if (!show_extra_peak) {
            row_info <- setdiff(row_info, c("Peak"))
        }

        row_info_df <- dff %>%
            select(c(Analyte, all_of(row_info))) %>%
            unique() %>%
            column_to_rownames(var = "Analyte")
        if ("Phospho" %in% all_of(row_info)) {
            row_info_df <- row_info_df %>%
                mutate(Phospho = as.factor(as.numeric(!is.na(Phospho))))
        }
        if ("Peak" %in% all_of(row_info)) {
                row_info_df <- row_info_df %>%
                mutate(Peak = as.factor(Peak))
        }
    }

    ## apply factor ordering
    if (length(factors) >0) {
        for (col in names(factors)) {
            dff <- dff %>%
                mutate("{col}" := droplevels(factor(.data[[col]], levels=factors[[col]])))
        }
    }

    ### dff is sorted according to the col_info list
    dff <- dff %>%
        arrange(across(col_info)) # arrange_(col_info)
    # if
    # extract the col.info
    col_info_df <- dff %>%
      select(c(Sample, all_of(rev(col_info)))) %>%
      unique() %>%
      column_to_rownames(var = "Sample") %>%
      data.frame()

    # convert to matrix
    heat_matrix <- dff %>%
      select(c(Sample, Analyte, all_of(data_col))) %>%
      pivot_wider(names_from = Analyte, values_from = all_of(data_col)) %>%# nolint
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
    ## adjustment for printing out

    if (!is.na(filename)) {
        if (!startsWith(filename, "/")) filename <- file.path(img_path, filename)
        message(str_glue("Saving plot to {filename}"))
    }
    # print(heat_matrix)
      # call the heatmap function
    heatmap <- heat_matrix %>%
      pheatmap(
        main=title,
        color = heat_color,
        annotation_row = row_info_df,
        annotation_col = col_info_df,
        annotation_colors = anno_colors,
        filename=filename,
        width=figsize[[2]],
        height=figsize[[1]],
        # passing defaults
        ...
      )
    return(heatmap)
}
