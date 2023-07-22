##### CONSTANTS #####################
# here you can enter all data stores and stuff that is needed for defaults etc
cyto_colors1 <- c(
    wo = "white",
    `IL-2` = "blue",
    CXCL9 = "#e1be83",
    CXCL10 = "#de6262",
    CXCL11 = "#9b3ad7"
)

cyto_colors2 <- c(
    wo = "white",
    `IL2` = "blue",
    CXCL9 = "#e1be83",
    CXCL10 = "#de6262",
    CXCL11 = "#9b3ad7"
)

stim_colors1 <- c(
    unstim = "white",
    stim = "green"
)

pop_colors1 <- c(
    `Tcm+Tscm` = "#ba77bf",
    `Tem+Temra` = "orange",
    `Tnaive` = "gray"
)

pop_colors2 <- c(
    `Tscm+Tcm` = "#ba77bf",
    `Tem+Temra` = "orange",
    `Tnaive` = "gray"
)


sarah_colors = list(
    Pop = pop_colors1,
    Cyto = cyto_colors1,
    Stim = stim_colors1
)

sarah_colors2 = list(
    Pop = pop_colors2,
    Cyto = cyto_colors2,
    Stim = stim_colors1
)

############ GHAZAL colors ############################

Cell_colors1 <- c(
    `non-Treg` = "white",
    `Unt-Treg` = "blue",
    `ko-Treg` = "#de6262"
)

Treatment_colors1 <- c(
    Medium = "white",
    Tac = "#de6262",
    CSA = "darkred"
)

ghazal_colors <- list(
    Cells = Cell_colors1,
    Treatment = Treatment_colors1
)
