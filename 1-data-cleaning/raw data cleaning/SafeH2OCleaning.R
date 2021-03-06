




rm(list=ls())
library("haven")
library("tidyverse")


#Improved water coding rules
#http://www.who.int/water_sanitation_health/monitoring/jmp2012/key_terms/en/

# Access to safe drinking water is measured by the percentage of the population using improved drinking-water sources.
# 
# Drinking water is water used for domestic purposes, drinking, cooking and personal hygiene.
# Safe drinking water is water considered safe if it meets certain microbiological and chemical standards on drinking water quality; guidance provided by the WHO Drinking-water Quality Guidelines (4th edition 2011).
# Access to safe drinking water is measured against the proxy indicator: the proportion of people using improved drinking water sources: household connection; public standpipe; borehole; protected dug well; protected spring; and rainwater collection.
# On premises piped drinking water connections - running water in dwelling, yard or plot.
# Improved drinking water source is a source that, by nature of its construction, adequately protects the water from outside contamination, in particular from faecal matter. Common examples:
#   piped household water connection
# public standpipe
# borehole
# protected dug well
# protected spring
# rainwater collection.
# Unimproved drinking water sources include:
#   unprotected dug well
# unprotected spring
# surface water (river, dam, lake, pond, stream, canal, irrigation channel)
# vendor-provided water (cart with small tank/drum, tanker truck)
# bottled water (bottled water is considered improved only when the household use another improved source for cooking and personal hygiene)
# tanker truck water .




#Function
load_san <- function(filepath, var=NULL){
  
  d <- readRDS(filepath)
  print(tolower(colnames(d)))
  colnames(d) <- tolower(colnames(d))
  
  if(!is.null(var)){
    vars <- c("studyid", "country", "subjid","agedays", var)
    d <- d %>% subset(., select=vars) %>%
      group_by(studyid, country, subjid) %>%
      arrange(agedays) %>%
      slice(1)
    print(table(d[,var[1]]))
  }
  return(d)
}



# Create pooled sanitation dataframe
dh20<-NULL


#-------------------------------
# ki0047075b-MAL-ED           
#-------------------------------

# e <- read.csv("U:/git/hbgd/ki0047075b/MALED-201707/adam/full_ki0047075b_MALED_201707.csv")
# df<-load_san("U:/data/mled.rds")

#may have to use compiled dataset values or search raw data


#Load SES data
d <- read.csv("U:/data/MALED-201501/import/WAMI_to24.csv")
head(d)

table(d$fsewdrink)

#Coding
# Piped into dwelling = 01; Piped to yard/plot = 02 ; Public tap/stand pipe= 03 ; Tube well or borehole = 04; 
# Protected well = 05; Unprotected well = 06 ;
# Surface water (river/ dam/ lake/pond/ stream/canal/irrigation canal) = 07 ; Other = 08

d$safeh20 <- NA
d$safeh20[d$fsewdrink<6 ] <- 0
d$safeh20[d$fsewdrink>5 ] <- 1
d$safeh20[d$fsewdrink==8 ] <- NA
table(d$safeh20)

#Load ID data
id <- readRDS("U:/data/mled.rds")
colnames(id) <- tolower(colnames(id))
id <- id %>% 
  group_by(studyid, country, subjid) %>%
  arrange(agedays) %>%
  slice(1) %>% subset(., select=c(studyid, country, subjid, subjido)) 

#merge id and sanitation
d <- d %>% subset(., select=c(PID, safeh20)) %>% rename(subjido = PID) 

dim(d)
d<- left_join(d, id, by="subjido")
dim(d)
table(d$safeh20)
table(is.na(d$subjid))
table(is.na(d$subjid), d$safeh20)
#d$subjido[is.na(d$subjid)]
#Missing IDs are all from pakistan- OK to drop
d<-d[!is.na(d$subjid),]

d <- subset(d, select = -c(subjido))

dh20<-bind_rows(dh20, d)





#-------------------------------
# ki1000125-AgaKhanUniv       
#-------------------------------

d<-load_san("U:/data/akup.rds", "h2osrc")
#all improved
d$safeh20<-1
d$safeh20[(d$h2osrc=="Other")] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)

#could maybe check raw data for more info
# d<-read_sas("U:/data/AgaKhanUniv/raw/hhdata.sas7bdat")
# head(d)
# table(d$cf11) #same info

#-------------------------------
# ki1000304-VITAMIN-A        
#-------------------------------

d<-load_san("U:/data/vita.rds", "h2osrc")
d$safeh20<-1
d$safeh20[d$h2osrc] 
d$safeh20[d$h2osrc=="Water trucks"] <- 0
d$safeh20[is.na(d$h2osrc)] <- NA

table(d$safeh20)

dh20<-bind_rows(dh20, d)

#-------------------------------
# ki1000304-ZnMort          
#-------------------------------

d<-load_san("U:/data/zmrt.rds", "h2osrc")

d$safeh20<-1
d$safeh20[is.na(d$h2osrc)] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1000304b-SAS-FoodSuppl    
#-------------------------------

d<-load_san("U:/data/fspp.rds", "h2osrc")

d$safeh20<-1
d$safeh20[is.na(d$h2osrc)] <- NA
table(d$safeh20)

#Check raw data -only 1 in the clean
# d<-read_sas("U:/git/hbgd/ki1000304b/SAS-FoodSuppl/raw/f2_baseline.sas7bdat")
# head(d)
# table(d$w_suply)

#3= public tap,  4= public hand pumps , 5=own hand pump

#No variation- all improved

dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1017093-NIH-Birth         
#-------------------------------

d<-load_san("U:/data/nbrt.rds", "h2osrcp")


d$safeh20<-1
d$safeh20[(d$h2osrcp)=="Well"] <- 0
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)


dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1017093b-PROVIDE        
#-------------------------------

d<-load_san("U:/data/prvd.rds", "h2osrcp")



d$safeh20<-1
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1017093c-NIH-Crypto      
#-------------------------------

d<-load_san("U:/data/ncry.rds", "h2osrc")

improved <- c("Septic tank or toilet", 
              "Water-sealed or slab latrine",
              "VIP with water seal",
              "Poor flash","Flash toilet")

d$safeh20<-1
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1112895-Burkina Faso Zn  
#-------------------------------

d<-load_san("U:/data/bfzn.rds", "h2osrcp")

#Check raw data to see source of var
#"1: improved in all seasons
# 2: improved only in one season
# 3: never improved"

d$safeh20 <- ifelse(as.numeric(d$h2osrcp)==1,1,0)
d$safeh20[d$h2osrcp==9] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1114097-CONTENT            
#-------------------------------

d<-load_san("U:/data/cntt.rds", "h2osrcc")

d$safeh20<-ifelse(d$h2osrcc=="Bottled water", 0, 1)
d$safeh20[(d$h2osrcc=="Don't use Water for Feeding Child")] <- NA
d$safeh20[is.na(d$h2osrcc)] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1135781-COHORTS          
#-------------------------------

d<-load_san("U:/data/cort.rds", "h2oavail")


# d<-read_sas("U:/data/COHORTS-201509/import/cohorts_sep22.sas7bdat")
# head(d)
# table(d$c3water)

#can't compare with other studies


#-------------------------------
# ki1148112-iLiNS-DOSE       
#-------------------------------

d<-load_san("U:/data/ilnd.rds", "h2osrcp")


improved <- c("Borehole","Piped Water" ,  "Protected Well" )

d$safeh20<-ifelse(d$h2osrcp %in% improved, 1, 0)
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)


dh20<-bind_rows(dh20, d)


#-------------------------------
# ki1148112-iLiNS-DYAD-M       
#-------------------------------

d<-load_san("U:/data/ildm.rds", "h2osrcp")


improved <- c("Borehole","Piped Water" ,  "Protected Well" )

d$safeh20<-ifelse(d$h2osrcp %in% improved, 1, 0)
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)


dh20<-bind_rows(dh20, d)




#-------------------------------
# ki1148112-LCNI-5      
#-------------------------------

d<-load_san("U:/data/lcn5.rds", "h2osrcp")

improved <- c("Borehole","Piped Water" ,  "Protected Well" )

d$safeh20<-ifelse(d$h2osrcp %in% improved, 1, 0)
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)


dh20<-bind_rows(dh20, d)


#-------------------------------
# kiGH5241-JiVitA-3     
#-------------------------------

d<-load_san("U:/data/jvt3.rds", "h2osrcp")

unimproved <- c("Surface/ring well" )


d$safeh20<-ifelse(d$h2osrcp %in% unimproved, 0, 1)
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)


#-------------------------------
# kiGH5241-JiVitA-4   
#-------------------------------

d<-load_san("U:/data/jvt4.rds", "h2osrcp")

unimproved <- c("Surface/ring well" )


d$safeh20<-ifelse(d$h2osrcp %in% unimproved, 0, 1)
d$safeh20[is.na(d$h2osrcp)] <- NA
table(d$safeh20)

dh20<-bind_rows(dh20, d)


#-------------------------------
# ilin-dyad-g 
#-------------------------------



# d<-read_sas("U:/data/iLins-Dyad-G/iLiNS-DYAD-G-201804/import/camf_long.sas7bdat")
# head(d)
# d<-read_sas("U:/data/iLins-Dyad-G/iLiNS-DYAD-G-201804/import/namf.sas7bdat")
# head(d)
# d<-read_sas("U:/data/iLins-Dyad-G/iLiNS-DYAD-G-201804/import/ws.sas7bdat")
# head(d)


#No water data


#-------------------------------
#ki1113344-GMS-Nepal   
#-------------------------------

d<-load_san("U:/data/gmsn.rds", "h2osrc")


unimproved <- c("Private Well" )


d$safeh20<-ifelse(d$h2osrc %in% unimproved, 0, 1)
d$safeh20[is.na(d$h2osrc)] <- NA
table(d$safeh20)



#-------------------------------
# examine full dataset
#-------------------------------

table(dh20$studyid, dh20$safeh20)

head(dh20)

dh20 <- subset(dh20, select = -c(h2osrc, h2osrcp, h2osrcc))

dh20 <- dh20 %>% 
  group_by(studyid, country, subjid) %>%
  arrange(agedays) %>%
  slice(1)

table(dh20$studyid, dh20$safeh20)


dh20 <- dh20 %>% subset(., select = -c(agedays))

save(dh20, file="U:/data/Raw Data Cleaning/improved_water_dataset.Rdata")
