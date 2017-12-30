install.packages("proj4")
#We need real time clinical and vector surveillance data to prevent arboviral outbreaks: 
#a retrospective study of Zika, Chikungunya, and Dengue outbreaks in Cali Colombia 2014-2016

library(haven)
ds <- read_stata("C://Users//amykr//Box Sync//Amy Krystosik's Files//cali- epi of arboviruses//cali.sivigila.arbovirus.2014-2016.dta")
table(ds$nom_eve, ds$cod_eve)

# lab results -------------------------------------------------------------
ds <- within(ds, Lab_result[ds$Lab_result == "Doubtfull"|ds$Lab_result == "Inadequate"|ds$Lab_result == "Non-Reactive"|ds$Lab_result == "Not Compatible"|ds$Lab_result =="Value registered"|ds$Lab_result =="Compatible"] <- "equivocal")
ds <- within(ds, Lab_result[ds$Lab_result == "Not processed"|ds$Lab_result == "Undefined"|ds$Lab_result == "No Data"] <- "No Data")
table(ds$Lab_result, ds$prueba, ds$nom_eve)

ds <- within(ds, prueba[ds$prueba == "4"] <- "PCR")
ds <- within(ds, prueba[ds$prueba == "E0"] <- "ELISA NS1")
ds <- within(ds, prueba[ds$prueba == "2"] <- "IgM")
ds <- within(ds, prueba[ds$prueba == "3"] <- "IgG")
ds <- within(ds, prueba[ds$prueba == "5"] <- "Viral Isolation")
ds <- within(ds, prueba[ds$prueba == ""] <- "No Data")

ds <- within(ds, prueba[ds$prueba == "11"|ds$prueba == "15"|ds$prueba == "16"|ds$prueba == "17"|ds$prueba == "18"|ds$prueba == "20"|ds$prueba == "25"|ds$prueba == "58"|ds$prueba == "84"|ds$prueba == "JA"|ds$prueba == "LA"|ds$prueba == "MO"] <- "not listed for DENV")
table(ds$prueba)

ds <- within(ds, agente[ds$agente == 3] <- "DENV")
table(ds$agente)

table(ds$prueba, ds$agente,ds$Lab_result)

table(ds$nom_eve)
1496/(1496+1208)*100#igm denv positive. n = 2704. 55.3% positive
28/(28+6)*100#pcr denv positive. n = 34. 82.4% positive
145/(145+70)*100#elisia ns1. n = 215. 67.4% positive.
ds$acute_testing<-0
ds <- within(ds, acute_testing[(ds$prueba == "ELISA NS1"|ds$prueba == "IgM"|ds$prueba == "PCR"|ds$prueba == "Viral Isolation")& ds$agente=="DENV"] <- 1)
table(ds$prueba, ds$agente)
table(ds$acute_testing)

ds$confirmed_acute<-"ND"
ds <- within(ds, confirmed_acute[ds$acute_testing ==1 & ds$Lab_result=="Negative"] <- "Confirmed -")
ds <- within(ds, confirmed_acute[ds$acute_testing ==1 & ds$Lab_result=="Positive"] <- "Confirmed +")
table(ds$confirmed_acute)


#function to convert week and year to date. 
library(lubridate)
calculate_start_of_week = function(semana, anos) {
  date <- ymd(paste(anos, 1, 1, sep="-"))
  week(date) = semana
  return(date)
}

ds$start_of_week = calculate_start_of_week(ds$semana, ds$anos)
ds$month2<-as.yearmon(ds$start_of_week)
# summarize by week -------------------------------------------------------
ds$event_confirmed=paste(ds$nom_eve, ds$confirmed_acute)
table(ds$event_confirmed)
table(ds$start_of_week, ds$event_confirmed)
cases_week<-table(ds$event_confirmed, ds$start_of_week)
cases_month<-table(ds$event_confirmed, ds$month2)

# graph cases by week -----------------------------------------------------
  barplot(cases_week,
          main="Distribution of Cases", 
          xlab="start of epidemiological week", 
          legend = rownames(cases_week))


  MyCol <- rainbow(11)
  x<-barplot(cases_week, col=MyCol, xaxt="n")
  MyLab_legend<- paste(rownames(cases_week))
  MyLab_axis <- paste(colnames(cases_week))
#  legend("top",  MyLab_legend,fill=MyCol,ncol=4, x.intersp=0.1, bty='n',text.width=c(10,10,10))
  text(cex=1, x=x-.25, y=-10.25, MyLab_axis, xpd=TRUE, srt=45, pos = 2)
  
# plotly ------------------------------------------------------------------
  library(plotly)
  
  t <- list(
    family = "sans serif",
    size = 36,
    color = 'black')
  f <- list(
    family = "sans serif",
    size = 28,
    color = 'black')
  
  m <- list(
    l = 100,
    r = 150,
    b = 150,
    t = 100,
    pad = 4
  )

cases_week<-  as.data.frame(cases_week)

disease <-  plot_ly() %>% 
    add_trace(data=cases_week, x = ~Var2, y = ~Freq, yaxis = "y", color = ~Var1)%>%
    add_trace(data=cases_week, x = ~Var2, y = ~Freq, yaxis = "y", color = ~Var1)%>%
    layout(
      title = 'Cases of DENV, CHIKV, and ZIKV reported to SIVIGILA',
      xaxis = list(type ="date", nticks = 15, tickangle =45,title = ""),
      yaxis = list(side = 'left', title = 'Total Cases/Week', showgrid = FALSE, zeroline = FALSE),
      barmode="stack",
      titlefont=t, font=f, autosize=T, margin = m)
  

#map the lab confirmed vs unconfirmed and lab pos pos vs negative.
library(rgdal)
cases_points<-readOGR("C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15/geo_direcciones_krystosik_5mayo2016B_latlon.shp")

merged_points<-merge(cases_points, ds, by="CODIGO")
table(merged_points$DDLat, exclude = NULL)
table(merged_points$`_merge`, exclude = NULL)
table(merged_points$acute_testing)
table(merged_points$confirmed_acute)

#install.packages("labelled")
library("labelled")
merged_points$`_merge`<-var_label(merged_points$`_merge`) <- NULL
merged_points$cases<-1
merged_points<-merged_points[order(-(grepl('CODIGO', names(merged_points)))+1L)]
merged_points$DDLat <-as.numeric(as.character(gsub("N", "", merged_points$DDLat)))
merged_points$DDLon <- as.numeric(as.character(gsub("W", "", merged_points$DDLon)))
merged_points$DDLon<-merged_points$DDLon*-1    

#geo
  points<- merged_points
  library(rgdal)  
  writeOGR(points, "C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15", "points", driver = "ESRI Shapefile",overwrite_layer=T)
  plot(points)
  points<-as.data.frame(points)
  points<-points[which(!is.na(points$DDLat))  , ]
  points<-points[, grepl("CODIGO|Lat|Lon", names(points))]
  points<-points[order(-(grepl('CODIGO', names(points)))+1L)]
  write.table(points,file="C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15/points.geo", quote = F, row.names = F)
#tested
  acute_testing_yes<- merged_points[which((merged_points$acute_testing==1))  , ]
  writeOGR(acute_testing_yes, "C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15", "acute_testing_yes", driver = "ESRI Shapefile")
  acute_testing_yes.cas<-  as.data.frame(acute_testing_yes)
  acute_testing_yes.cas<-acute_testing_yes.cas[, grepl("CODIGO|cases|start_of_week", names(acute_testing_yes.cas))]
  acute_testing_yes.cas<-acute_testing_yes.cas[order(-(grepl('case', names(acute_testing_yes.cas)))+1L)]
  acute_testing_yes.cas<-acute_testing_yes.cas[order(-(grepl('CODIGO', names(acute_testing_yes.cas)))+1L)]
  write.table(acute_testing_yes.cas,file="C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15/acute_testing_yes.cas", quote = F, row.names = F)
  

  acute_testing_no<- merged_points[which((merged_points$acute_testing==0))  , ]
  writeOGR(acute_testing_no, "C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15", "acute_testing_no", driver = "ESRI Shapefile")
  acute_testing_no.ctl<-  as.data.frame(acute_testing_no)
  acute_testing_no.ctl<-acute_testing_no.ctl[, grepl("CODIGO|cases|start_of_week", names(acute_testing_no.ctl))]
  acute_testing_no.ctl<-acute_testing_no.ctl[order(-(grepl('case', names(acute_testing_no.ctl)))+1L)]
  acute_testing_no.ctl<-acute_testing_no.ctl[order(-(grepl('CODIGO', names(acute_testing_no.ctl)))+1L)]
  write.table(acute_testing_no.ctl,file="C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15/acute_testing_no.ctl", quote = F, row.names = F)
  
  table(acute_testing_no$start_of_week)
  #confirmed acute cases
  confirmed_acute_pos<- merged_points[which((merged_points$confirmed_acute=="Confirmed +"))  , ]
  writeOGR(confirmed_acute_pos, "C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15", "confirmed_acute_pos", driver = "ESRI Shapefile")
  confirmed_acute_pos.cas<-  as.data.frame(confirmed_acute_pos)
  confirmed_acute_pos.cas<-confirmed_acute_pos.cas[, grepl("CODIGO|cases|start_of_week", names(confirmed_acute_pos.cas))]
  confirmed_acute_pos.cas<-confirmed_acute_pos.cas[order(-(grepl('case', names(confirmed_acute_pos.cas)))+1L)]
  confirmed_acute_pos.cas<-confirmed_acute_pos.cas[order(-(grepl('CODIGO', names(confirmed_acute_pos.cas)))+1L)]
  write.table(confirmed_acute_pos.cas,file="C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15/confirmed_acute_pos.cas", quote = F, row.names = F)
  
  confirmed_acute_neg<- merged_points[which((merged_points$confirmed_acute=="Confirmed -"))  , ]
  writeOGR(confirmed_acute_neg, "C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15", "confirmed_acute_neg", driver = "ESRI Shapefile")
  confirmed_acute_neg.ctl<-  as.data.frame(confirmed_acute_neg)
  confirmed_acute_neg.ctl<-confirmed_acute_neg.ctl[, grepl("CODIGO|cases|start_of_week", names(confirmed_acute_neg.ctl))]
  confirmed_acute_neg.ctl<-confirmed_acute_neg.ctl[order(-(grepl('case', names(confirmed_acute_neg.ctl)))+1L)]
  confirmed_acute_neg.ctl<-confirmed_acute_neg.ctl[order(-(grepl('CODIGO', names(confirmed_acute_neg.ctl)))+1L)]
  write.table(confirmed_acute_neg.ctl,file="C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15/confirmed_acute_neg.ctl", quote = F, row.names = F)



plot(confirmed_acute_pos)
plot(confirmed_acute_neg)
plot(acute_testing_no)
plot(acute_testing_yes)

#install.packages("rsatscan")
library("rsatscan")
  ss.options("C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15","confirmed_acute_pos")
  write.ss.prm("C:/Users/amykr/Google Drive/Kent/james/dissertation/chkv and dengue/data/municipal data/georeferenced cases june 15","cali_cases")
  satscan("C:/Program Files/SaTScan/SaTScan")
  summary(satscanresult)