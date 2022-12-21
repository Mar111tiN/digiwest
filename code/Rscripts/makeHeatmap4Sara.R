library(tidyverse)
library(readxl)

##################################
## SETUP #########################
# Sys.getenv loads environment variables
home <- Sys.getenv('HOME')
hook <- file.path(home, "Sites/sceleton/code/R")
work <- Sys.getenv('WORK')

###  LOAD CONFIG ###############
source(file.path(hook,"setup.R"))
load_config("/Users/martinszyska/Dropbox/Icke/Work/DigiWest/DigiWestBioinfo/code/config/sarah_config.yml")

#######################################
######## EXECUTE ######################

sarah.csv <- file.path(tables_path,"221221-sarah.csv")
sarah.config <- file.path(config_path, "sarah_config.yml")
sarah.config

plot_config <- read_yaml(sarah.config)$plot_heatmap
df <- read_tsv(sarah.csv)
glimpse(df)

(test <- digi_heatmap(
  table_file=sarah.csv,
  plot_file=file.path(img_path, "sarah_test"),
  max_NA=0.9, 
  exclude_IL2 = T, 
  show_extra_peak=F,
  show_phospho_only=F,
  data_col = "logMFI_sc_minWO",
  cutree_cols = 3,
  cluster_cols = F,
  show_colnames = F,
  row_info = plot_config$row_info,
  col_info = plot_config$col_info,
  show_data = plot_config$show_data,
  hide_data = plot_config$hide_data,
  anno_colors = sarah_colors
  ))


test_config <- file.path(config_path, "sarah_config.yml")
## test with config file
(info <- digi_wrapper(
  config_file=sarah.config,
  table_file=sarah.csv,
  data_col = "logMFI_sc_minCXCL10",
  cluster_cols=T,
  main="Digiwest",
  show_phospho_only=F,
  show_extra_peak=T,
  plot_file="test",
  fontsize_row= 6,
  anno_colors = sarah_colors
))



for (cluster in c(T, F)) {
  for (full in c(T, F)) {
    for (stim_only in c(T, F)) {
      for (data_col in c("medMFI", "logMFI")) {
        for (scale in c("", "WO", "CXCL9", "CXCL10")) {
          for (show in c("select", "all")) {
            # defaults
            show_phospho_only<-T
            show_extra_peak<-F
            show_stims <- c("unstim", "stim")
            cluster_cols <- F
            show_cytos <- c("IL-2", "wo", "CXCL9", "CXCL10", "CXCL11")
            col_info <- c("Cyto", "Pop")  #  col_info <- c("Cyto", "Pop", "Stim")
            fontsize_row <- 10
            
            title <- "DigiWest"
            file <- "DigiWest"
            data <- str_glue("{data_col}_sc")
            title <- str_glue("{title} | {data_col}")
            file <- str_glue("{file}_{data_col}")
            
            if (scale != "") {
              data <- str_glue("{data}_min{scale}")
              title <- str_glue("{title} vs {scale}")
              file <- str_glue("{file}_vs_{scale}")
            }
            if (show == "select") {
              file <- str_glue("{file}_select")
              if (scale == "WO") {
                show_cytos <- c("CXCL9", "CXCL10", "CXCL11")
              }
              if (scale %in% c("CXCL9", "CXCL10")) {
                show_cytos <- c("CXCL9", "CXCL10", "CXCL11")
                show_cytos <- show_cytos[show_cytos != scale]
                col_info <- c("Cyto", "Pop", "Stim")
              }
              if (scale == "") {
                next
              }
            }
            if (stim_only) {
              title <- str_glue("{title} | stimulated")
              file <- str_glue("{file}_stim")
              show_stims <- c("stim")
              
            } else {
              title <- str_glue("{title} | unstimulated")
              file <- str_glue("{file}_unstim")
              show_stims <- c("unstim")
              
            }
            if (cluster) {
              file <- str_glue("{file}_clust")
              cluster_cols <- T
            }
            if (full) {
              file <- str_glue("{file}_full")
              show_phospho_only<-F
              show_extra_peak<-T
              fontsize_row <- 6
            } else {
              title <- str_glue("{title} | Phospo only")
            }
            print(title)
            print(file)
            digi_wrapper(
              config_file=test_config,
              table_file="220405-tidy3.csv",
              cluster_cols=cluster_cols,
              data_col=data,
              main=title,
              plot_file=file,
              show_phospho_only=show_phospho_only,
              show_extra_peak=show_extra_peak,
              fontsize_row=fontsize_row,
              show_stims=show_stims,
              col_info=col_info,
              show_cytos=show_cytos
            )
          }
        }
      }
    }
  }
}





############################# execute the rest #########
for (data_col in c(
  "medMFI_sc",
  "logMFI_sc",
  "medMFI_minWO_sc",
  "medMFI_divWO_sc",
  "logMFI_divWO_sc"
)) {
  for(cluster in c(T,F)) {
    plot <- ppheatmap(data.filtered, 
                      data.col = data_col,
                      main = data_col,
                      cutree_cols=3, 
                      cluster_cols=cluster, 
                      show_colnames = F, 
                      row_info = c("Peak"),
                      color = viridis(n = 256, alpha = 1, option="magma")
    )
    save_pheatmap_pdf(plot, str_glue("{save.path}/heatmap-{data_col}{if_else(cluster, '_clust', '')}.pdf"))
  }
}
