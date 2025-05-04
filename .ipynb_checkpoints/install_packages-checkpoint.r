# install_packages.R

packages <- c(
  "dplyr",
  "lubridate",
  "fda",
  "tidyr",
  "MASS"
)

install_if_missing <- setdiff(packages, rownames(installed.packages()))
if (length(install_if_missing)) {
  install.packages(install_if_missing)
}


# To use: source("install_packages.R")