#amy r krystosik, february 20, 2017, akrystos@stanford.edu
#submitted as part of manuscript submission to CDC EID.
#raw data for making html animations and maps
#ran in R-studio Version 1.0.136 – © 2009-2016 RStudio, Inc.

#set your working directory to wherever you save the sts objects
setwd ("C:/Users/amykr/Box Sync/Amy Krystosik's Files/cali- epi of arboviruses/epi paper/figures/Figure 4 editable sts objects and code") 

#install necessary packages and library
#install.packages(c("animation", "surveillance", "gridExtra", "sp", "maptools", "extrafont"))
library(extrafont)
library(sp)
library(xts)
library(maptools)
library(surveillance)
library(dplyr)
library(tidyr)
library(animation)

#load files from working directory
load(file="denguecounts_sts.R")
#make map of counts of dengue by neighborhood 
tiff("denv_case_counts_all.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
plot(denguecounts_sts, type = observed~unit , sub = "Dengue")
dev.off()
#make map animation of counts of dengue by neighborhood over time
#animation::saveHTML(animate(denguecounts_sts, tps=1:15, total.args = list()), img.name="chikvchikvcounts_sts", title ="Evolution of Dengue outbreak in Cali, Colombia, 11/2015 - 4/2016", ani.width = 500, ani.height = 600)

#repeat for confirmed dengue
load(file="dengue_c.counts_sts.R")
tiff("confirmed_denv_case_counts.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
plot(denguecounts_sts, type = observed~unit , sub = "Confirmed Dengue")
dev.off()
#animation::saveHTML(animate(chikvcounts_sts, tps=1:15, total.args = list()), img.name="chikvchikvcounts_sts", title ="Evolution of Chikungunya outbreak in Cali, Colombia, 1/2015 - 4/2016", ani.width = 500, ani.height = 600)

#repeat for chikungunya
load(file="chikvcounts_sts.R")
tiff("chikv_case_counts.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
plot(chikvcounts_sts, type = observed~unit , sub = "Chikungunya")
dev.off()
#animation::saveHTML(animate(chikvcounts_sts, tps=1:15, total.args = list()), img.name="chikvchikvcounts_sts", title ="Evolution of Chikungunya outbreak in Cali, Colombia, 1/2015 - 4/2016", ani.width = 500, ani.height = 600)

#repeat for zika
load(file="zikacounts_sts.R")
tiff("zika_case_counts.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
plot(zikacounts_sts, type = observed~unit , sub = "Zika")
dev.off()
#animation::saveHTML(animate(zikacounts_sts, tps=1:15, total.args = list()), img.name="chikvchikvcounts_sts", title ="Evolution of Zika outbreak in Cali, Colombia, 11/2015 - 4/2016", ani.width = 500, ani.height = 600)


