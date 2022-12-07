library(tidyverse)
library(readxl)
library(pheatmap)

home_path <- Sys.getenv('WORK')
base_path <- file.path(home_path, "DigiWest")
setwd(base_path)

source("code/R/setup.R")
source(file.path(R_path, "utils.R"))

table_file <-file.path(tables_path, "220405-tidy3.csv")


(
  df <- read_tsv(str_glue(table_file)) %>% 
  filter_data(
    max_NA=0.9,
    show_extra_peak = FALSE,
    show_phospho_only = TRUE
  )
)
glimpse(df)


df2mat <- function(df, data_col="logMFI_sc") {
  df %>%
    select(c(Sample, Pop, Stim, Cyto, Analyte, all_of(data_col))) %>%
    pivot_wider(id_cols = c(), names_from = Analyte, values_from = all_of(data_col)) %>% # nolint
    column_to_rownames(var = "Sample") %>%
    as.matrix() %>%
    t()
}

(
  mat <- df %>% 
  df2mat(
    data_col = "logMFI_sc"
  )
)
glimpse(mat)

data_col = "logMFI_sc"



mat <- df2mat(data)

data <- filter_data()