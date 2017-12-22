#We need real time clinical and vector surveillance data to prevent arboviral outbreaks: 
#a retrospective study of Zika, Chikungunya, and Dengue outbreaks in Cali Colombia 2014-2016

library(haven)
ds <- read_stata("C:\\Users\\amykr\\Box Sync\\Amy Krystosik's Files\\cali- epi of arboviruses\\cali.sivigila.arbovirus.2014-2016.dta")
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
ds$acute_testing<-NA
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
  

