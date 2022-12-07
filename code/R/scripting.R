# load the home path
# Sys.getenv loads environment variables
home_path <- Sys.getenv('HOME')

# compose the base_path from path relative to home
# !!!!! you have to set this to the root path of the sceleton folder
# or however you have renamed it to
# can also be absolute path without str_glue
base_path <- file.path(home_path, "Sites/tuto/sceleton")

# this loads the code from setup.R that auto-sets the paths that are
# ..fixed relative to the base_folder (can be adjusted to your structure)
# if you stick to the folder structure, you can leave it as-is
setwd(base_path)
source("code/R/setup.R")

### here you can load the code that you:
  # either always use (should become part of your own "sceleton")
  # you refactored as project-specific code base
  # you can move them later to a central code base (or github)
# load the functions and configs used for plotting the data and config_loading
source(file.path(R_path, "plot.R"))
source(file.path(R_path, "utils.R"))

# setting the files for loading the data
stat.file <- file.path(data_path, "stat3.csv")
qPCR_file <- file.path(data_path, "qPCR.csv")
pdf.file <- file.path(img_path, "test_figure.pdf")

stat.func

#### the function combined_plot is loaded from plot.R
# it has a lot of settings that you can play with
combined_plot(
  stat.file, qPCR_file,
  save.fig = pdf.file,
  save.dims = c(8, 11),
  box.width = .45,
  jitter.width = 0.03,
  alpha = 0.9,
  point.size = 1,
  text.size = 15,
  boxplot.type = 5,
  pop.colors = Tcell_colors,
  pop.label = Tcell_pop_labels,
  pop.levels = Tcell_pops,
  stat.label = "Fold increase to w/o",
  qPCR.label = "mRNA relative expression",
  qPCR.isoform = "alt",
  stim.time = 30
)

#### for easier control, the graphical settings can be placed in a 
# yaml file that controls many of these settings
# you can change these settings and rerun the function
# parameters in function call overrule yaml-settings to combine defaults and current settings
config.default <- file.path(config_path, "plot_config.yml")

config_wrapper(
  stat.file, qPCR_file,
  save.fig = pdf.file,
  qPCR.isoform = "alt",  # "A", "B" or "alt"
  stim.time = 30,  # 5,15, 30, 60
  config_file = config.default
)

### so you can also store several graphics settings and load them when needed
# ... for different publications, presentations etc.
config.gray <- file.path(config_path, "plot_config_gray.yml")


config_test(config.default)


config_wrapper(
  stat.file, qPCR_file,
  save.fig = pdf.file,
  qPCR.isoform = "alt",
  stim.time = 30,  # 5,15, 30, 60
  config_file = config.gray
)
