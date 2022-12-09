library(tidyverse)
library(readxl)

##################################
## SETUP #########################
# Sys.getenv loads environment variables
home <- Sys.getenv('HOME')
hook <- file.path(home, "Sites/sceleton/code/R")
work <- Sys.getenv('WORK')

# here set the repo path
repo_path <- getwd()
###  LOAD CONFIG ###############
source(file.path(hook,"setup.R"))
load_config(file.path(repo_path, "config/test_config.yml"))

#######################################
######## EXECUTE ######################

sarah.csv <- file.path(tables_path,"digi_test.csv")
sarah.config <- file.path(config_path, "test_config.yml")
plot_config <- read_yaml(sarah.config)$plot_heatmap
df <- read_tsv(sarah.csv)
glimpse(df)

(test <- digi_heatmap(
  table_file=sarah.csv,
  plot_file=file.path(img_path, "test_img"),
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


test_config <- file.path(config_path, "test_config.yml")
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


