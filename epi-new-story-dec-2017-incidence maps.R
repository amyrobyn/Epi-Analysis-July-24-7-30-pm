#amy r krystosik, february 20, 2017, akrystos@stanford.edu
#submitted as part of manuscript submission to CDC EID.
#raw data for making incidence maps from Figure 3
#ran in R-studio Version 1.0.136 2009-2016 RStudio, Inc.


#set your working directory to wherever you save the sts objects
setwd ("C:/Users/amykr/Box Sync/Amy Krystosik's Files/cali- epi of arboviruses/epi paper/figures/Figure 3 editable shapefiles and spatial objects and code") 
#install necessary packages and library

library(rgdal)
library(sp)
library(RColorBrewer)
library(classInt)

load(file="./denvincidence.R")
load(file="./chikvincidence.R")
load(file="./zikaincidence.R")
load(file="./denv_c_incidence.R")


display.brewer.all(type="seq")
pal <- brewer.pal(9, "YlOrRd")# we select 9 colors from the palette, choose the one you like. 

denv_breaks <- classIntervals(denvincidence$crudeincidence_barriosum1000, n = 9)
str(denv_breaks)
denv_breaks$brks

denv_c_breaks <- classIntervals(denv_c_incidence$denv_c_inc_100000, n = 5)
str(denv_c_breaks)
denv_c_breaks$brks

chikv_breaks <- classIntervals(chikvincidence$crudeincidence_barriosum1000, n = 9)
str(chikv_breaks)
chikv_breaks$brks

zika_breaks <- classIntervals(zikaincidence$crudeincidence_barriosum1000, n = 9)
str(zika_breaks)
zika_breaks$brks


# add a very small value to the top breakpoint, and subtract from the bottom for symmetry 
zikabr <- zika_breaks$brks 

chikvbr <- chikv_breaks$brks 

denvbr <- denv_breaks$brks 

denv_c_breaks<-denv_c_breaks$brks

denvincidence$crudeincidence_barriosum1000_bracket <- cut(denvincidence$crudeincidence_barriosum1000, denvbr)
head(denvincidence$crudeincidence_barriosum1000_bracket )
class(denvincidence$crudeincidence_barriosum1000_bracket )
tiff("denvincidence.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
spplot(denvincidence, "crudeincidence_barriosum1000_bracket", col.regions=pal, main = "Dengue incidence \nper 1,000 population", sub = "Source: SIVIGILA & DANE \n October 2014 - March 2016") 
dev.off()

denv_c_incidence$denv_c_inc_100000_bracket <- cut(denv_c_incidence$denv_c_inc_100000, denv_c_breaks)
head(denv_c_incidence$denv_c_inc_100000_bracket )
class(denv_c_incidence$denv_c_inc_100000_bracket )
tiff("confirmed_denvincidence.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
spplot(denv_c_incidence, "denv_c_inc_100000_bracket", col.regions=pal, main = "Confirmed Dengue incidence \nper 1,000 population", sub = "Source: SIVIGILA & DANE \n October 2014 - March 2016") 
dev.off()

chikvincidence$crudeincidence_barriosum1000_bracket <- cut(chikvincidence$crudeincidence_barriosum1000, chikvbr)
tiff("chikvincidence.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
spplot(chikvincidence, "crudeincidence_barriosum1000_bracket", col.regions=pal, main = "Chikungunya incidence per \n1,000 population", sub = "Source: SIVIGILA & DANE \n Jan. 2015 - March 2016")
dev.off()

zikaincidence$crudeincidence_barriosum1000_bracket <- cut(zikaincidence$crudeincidence_barriosum1000, zikabr)
tiff("zikaincidence.tiff", height = 12, width = 17, units = 'cm', compression = "lzw", res = 600)
spplot(zikaincidence, "crudeincidence_barriosum1000_bracket", col.regions=pal, main = "Zika incidence \nper 1,000 population", sub = "Source: SIVIGILA & DANE \nNov. 2015 - March 2016")
dev.off()
