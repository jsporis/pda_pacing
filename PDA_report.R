require(RJDBC)
require(jsonlite)
require(ggplot2)
require(reshape2)
require(scales)
require(GAR)
require(lubridate)
require(dplyr)


##GET TOKEN
tokenRefresh()

##SET DATE CONSTANTS

date.today <- Sys.Date()
date.start.current <- date.today-day(date.today)+1

date.start.prior <- date.today-day(date.today)
date.start.prior <- date.start.prior-day(date.start.prior)+1

date.end.prior <- date.today-day(date.today)
days.current.month <- as.numeric(date.today-date.start.current)+1

last.day.current <- as.numeric(days_in_month(Sys.Date()))
last.day.prior <- as.numeric(days_in_month(month(date.today)-1))

date.end.current  <- (date.start.current+last.day.current)-1




##DASHBOARD UPDATE TIME

ctime <- as.character(Sys.time())
ctime <- paste("Dashboard updated at: ", ctime)


##CONNECT TO MYSQL DB

mysql_jar <- '../source_files/mysql-connector-java-5.1.24-bin.jar'

drv <- JDBC("com.mysql.jdbc.Driver",mysql_jar,identifier.quote="`")

conn <- dbConnect(drv, Sys.getenv('IO_DB_05RJDBC'), Sys.getenv('IO_DB_USER'), Sys.getenv('IO_DB_PW'))

##MYSQL QUERY DATA INTEGRATION
l_count_query <- "
SELECT date(created_at) date, count(*) l_count 
FROM pda_corporate.ContactMessage
WHERE email NOT LIKE '%iostudio%'
AND email NOT LIKE '%qatest%'
AND email NOT LIKE '%scottarenz%'
AND email NOT LIKE '%christianreedanderson%'
AND email NOT LIKE '%fakeemail%'
AND email NOT LIKE 'qa@qa.com'
AND email NOT LIKE '%pdateam.com%'
group by date(created_at)"


l_count <- dbGetQuery(conn, l_count_query)
dbDisconnect(conn)



##CURRENT MONTH VISITS
visits.current <- gaRequest(
  id='ga:94126319',  
  metrics='ga:visits', 
  start=as.character(date.start.current), 
  end=as.character(date.today)
)

visits.current <- visits.current$visits


##PRIOR MONTH VISITS
visits.prior <- gaRequest(
  id='ga:94126319',  
  metrics='ga:visits', 
  start=as.character(date.start.prior), 
  end=as.character(date.end.prior)
)

visits.prior <- visits.prior$visits



##CURRENT VISITS BY DAY

cbd <- gaRequest(
  id='ga:94126319', 
  dimensions='ga:date',
  metrics='ga:visits', 
  start=as.character(date.start.current), 
  end=as.character(date.today)
)

cbd <- cbd[,c('date','visits')]
cbd$date <- as.Date(strptime(cbd$date, '%Y%m%d'))
colnames(cbd) <- toupper(colnames(cbd))



##CREATE MERGED VISIT DAILY DATA FRAME  
daily.need <- visits.prior/last.day.current
cur.month.need <- days.current.month*daily.need

data.daily <- data.frame( DATE=seq(date.start.current,date.end.current, by = 1), 'ESTIMATED NEED'= daily.need)
data.daily$ESTIMATED.NEED <- cumsum(data.daily$ESTIMATED.NEED)

data.daily <- merge(data.daily, cbd, all.x=TRUE)
data.daily$RUNNING.TOTAL <- cumsum(data.daily$VISITS)
colnames(data.daily) <- gsub('\\.',' ', colnames(data.daily))
data.daily$DATE <- as.character(format(data.daily$DATE, '%m-%d'))
data.daily <- melt(data.daily)
data.daily <- data.daily[!(is.na(data.daily$value)),]


rm(cbd)


##CURRENT LEADS BY DAY

cld <- l_count
cld$date <- as.Date(cld$date)
colnames(cld) <- c("DATE","LEADS")

##CURRENT MONTH LEADS
leads.current <- filter(l_count, date >= date.start.current & date <= date.today)%>%
  summarize(LEADS=sum(l_count))
leads.current <- leads.current$LEADS
##PRIOR MONTH LEADS
leads.prior <- 
  filter(l_count, date >= date.start.prior & date <= date.end.prior)%>%
  summarize(LEADS=sum(l_count)) 
leads.prior <- leads.prior$LEADS

##CREATE MERGED LEAD DAILY DATA FRAME  
daily.lead.need <- leads.prior/last.day.current
cur.month.lead.need <- days.current.month*daily.lead.need

data.lead.daily <- data.frame( DATE=seq(date.start.current,date.end.current, by = 1), 'ESTIMATED NEED'= daily.lead.need)
data.lead.daily$ESTIMATED.NEED <- cumsum(data.lead.daily$ESTIMATED.NEED)

data.lead.daily <- merge(data.lead.daily, cld, all.x=TRUE)
data.lead.daily[is.na(data.lead.daily) & data.lead.daily$DATE <= date.today] <- 0
data.lead.daily$RUNNING.TOTAL <- cumsum(data.lead.daily$LEADS)
colnames(data.lead.daily) <- gsub('\\.',' ', colnames(data.lead.daily))
data.lead.daily$DATE <- as.character(format(data.lead.daily$DATE, '%m-%d'))
data.lead.daily <- melt(data.lead.daily)
data.lead.daily$value[data.lead.daily$value==0 & data.lead.daily$variable != 'RUNNING TOTAL']  <- NA
data.lead.daily <- data.lead.daily[!(is.na(data.lead.daily$value)),]

rm(cld)


#VISIT PACING SCORE

visit_pacing_score <- paste(
  round((visits.current/cur.month.need)*100,0 ),
  "%",sep=""
)

#LEAD PACING SCORE

lead_pacing_score <- paste(
  round((leads.current/cur.month.lead.need)*100,0 ),
  "%",sep=""
)

#DAILY VISITS CHART

plot.max <- c(0,max(data.daily$value)*1.05)
daily.chart <- 
  
  ggplot()+
  geom_line(data = filter(data.daily, variable =='ESTIMATED NEED'), aes(x=DATE,y=value,group=variable, color="est"), linetype=2, size = 1) +
  geom_bar(data = filter(data.daily, variable =='VISITS'), aes(x=DATE,y=value, fill = "#2BA673"), stat = "identity") +
  geom_line(data = filter(data.daily, variable =='RUNNING TOTAL'), aes(x=DATE,y=value,group=variable, color="running"),linetype=1, size = 1) +
  geom_point(data = filter(data.daily, variable =='ESTIMATED NEED',value == max(value)), aes(x=DATE,y=value,group=variable), color="#9a9a9a", size = 8) +
  geom_point(data = filter(data.daily, variable =='RUNNING TOTAL'), aes(x=DATE,y=value,group=variable), color="#575757", size = 4) +
  scale_fill_identity(name = 'BARS', guide = 'legend',labels = c('VISITS BY DAY')) +
  scale_colour_manual(name = 'LINES', values =c("est"='#9a9a9a',"running"='#575757'), labels = c('PRIOR MONTH TOTAL',"CURRENT RUNNING TOTAL")) +
  theme(
    text=element_text(color="#1A2D2E"),
    axis.line=element_blank(),
    axis.ticks=element_blank(),
    axis.title.y=element_blank(),
    axis.text.y=element_text(size = 10),
    axis.text.x=element_text(size = 12, angle=90),
    axis.title.x=element_blank(),
    legend.position="top",
    legend.text=element_text(size=12),
    legend.title=element_blank(),
    panel.border=element_blank(),
    panel.background=element_blank(),
    plot.background=element_blank()) +
  scale_y_continuous(limit=plot.max) +
  geom_text(data = filter(data.daily, variable =='VISITS'),aes(x=DATE, y=0, label = value), vjust=1.25, size = 4, color = "#45688D") +
  geom_text(data = filter(data.daily, variable =='ESTIMATED NEED', value == max(value)) ,aes(x=DATE, y=value, label = value), vjust=-1.75 ,size = 4, color = "#45688D")

#DAILY LEADS CHART

plot.max <- c(0,max(data.lead.daily$value)*1.05)
daily.lead.chart <- 
  
  ggplot()+
  geom_line(data = filter(data.lead.daily, variable =='ESTIMATED NEED'), aes(x=DATE,y=value,group=variable, color="est"), linetype=2, size = 1) +
  geom_bar(data = filter(data.lead.daily, variable =='LEADS'), aes(x=DATE,y=value, fill = "#2BA673"), stat = "identity") +
  geom_line(data = filter(data.lead.daily, variable =='RUNNING TOTAL'), aes(x=DATE,y=value,group=variable, color="running"),linetype=1, size = 1) +
  geom_point(data = filter(data.lead.daily, variable =='ESTIMATED NEED',value == max(value)), aes(x=DATE,y=value,group=variable), color="#9a9a9a", size = 8) +
  geom_point(data = filter(data.lead.daily, variable =='RUNNING TOTAL'), aes(x=DATE,y=value,group=variable), color="#575757", size = 4) +
  scale_fill_identity(name = 'BARS', guide = 'legend',labels = c('LEADS BY DAY')) +
  scale_colour_manual(name = 'LINES', values =c("est"='#9a9a9a',"running"='#575757'), labels = c('PRIOR MONTH TOTAL',"CURRENT RUNNING TOTAL")) +
  theme(
    text=element_text(color="#1A2D2E"),
    axis.line=element_blank(),
    axis.ticks=element_blank(),
    axis.title.y=element_blank(),
    axis.text.y=element_text(size = 10),
    axis.text.x=element_text(size = 12, angle=90),
    axis.title.x=element_blank(),
    legend.position="top",
    legend.text=element_text(size=12),
    legend.title=element_blank(),
    panel.border=element_blank(),
    panel.background=element_blank(),
    plot.background=element_blank()) +
  scale_y_continuous(limit=plot.max) +
  geom_text(data = filter(data.lead.daily, variable =='LEADS'),aes(x=DATE, y=0, label = value), vjust=1.25, size = 4, color = "#45688D") +
  geom_text(data = filter(data.lead.daily, variable =='ESTIMATED NEED', value == max(value)) ,aes(x=DATE, y=value, label = value), vjust=-1.75 ,size = 4, color = "#45688D")



daily.chart
daily.lead.chart
