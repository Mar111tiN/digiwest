# this file contains all functionality for path setting
# several paths are hardcoded to reflect the fixed structure of your project folder
data_path <- file.path(base_path, "data")
output_path <- file.path(base_path, "output")
img_path <- file.path(output_path, "img")
tables_path <- file.path(output_path, "tables")

# create the image folder, if it does not exist
dir.create(img_path, showWarnings = FALSE)
config_path <- file.path(base_path, "code/config")
R_path <- file.path(base_path, "code/R")




