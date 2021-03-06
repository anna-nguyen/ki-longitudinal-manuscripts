##########################################
# ki longitudinal manuscripts
# stunting analysis
#
# ben arnold (benarnold@berkeley.edu)
# modified by jade benjamin-chung (jadebc@berkeley.edu)
#
# create a heatmap of data availability
# for weight and height by study 
# in GHAP using meta-data
# (GHAP_metadata) that Andrew created
# using GHAPStudyMetadata.R

# inputs: GHAP_metadata_stunting.RDS

# outputs: 
# "fig-stunt_laz-2-heatmap-overall--allage-primary.png"
# "figdata-stunt_laz-2-heatmap-overall--allage-primary.RDS"
##########################################

#-----------------------------------
# preamble
#-----------------------------------
rm(list=ls())
source(paste0(here::here(), "/0-config.R"))

#-----------------------------------
# load the meta-data table from Andrew (GHAP_metadata)
#-----------------------------------
md <- readRDS('results/GHAP_metadata_stunting.RDS')

#Drop non-included studies
md <- mark_measure_freq(md)
table(md$measurefreq)

md <- md %>% filter(measurefreq!="yearly" & !is.na(measurefreq))

unique(md$study_id)

#drop yearly COHORTS
md <- md[!(md$study_id=="COHORTS" & (md$countrycohort=="BRAZIL"|md$countrycohort=="SOUTH AFRICA")),] 

dim(md)
md$countrycohort[is.na(md$countrycohort)] <- "singlecohort"


#drop mal-ed Pakistan
md <- md[!(md$study_id=="MAL-ED" & md$countrycohort=="singlecohort"),]
dim(md)


# convert stunting prevalence and numsubj to numeric
md$stuntprev <- as.numeric(md$stuntprev)
md$numsubj <- as.numeric(md$numsubj)
for(i in 0:24){
  ni <- paste("n",i,sep="")
  wi <- paste("stuntprev_m",i,sep="")
  md[ni] <- as.numeric(md[,c(ni)])
  md[wi] <- as.numeric(md[,c(wi)])
}


# convert mean HAZ to numeric
for(i in 0:24){
  wi <- paste("meanHAZ_m",i,sep="")
  md[wi] <- as.numeric(md[,c(wi)])
}


# calculate the total number of measurements
md$nmeas <- rowSums(md[,paste('n',0:24,sep='')],na.rm=TRUE)

dd <- md







#-----------------------------------
# Do some final tidying up for the plot
#-----------------------------------


# shorten the description for a few studies
dd <- shorten_descriptions(dd)

# # simplify Tanzania label
dd$countrycohort[dd$countrycohort=='TANZANIA, UNITED REPUBLIC OF'] <- 'TANZANIA'

# make a study-country label, and make the monthly variable into a factor
# including an anonymous label (temporary) for sharing with WHO
dd <- mutate(dd,
             country=str_to_title(str_to_lower(countrycohort)), 
             studycountry=paste0(short_description,', ',country)) 

#Add regions with ugly Europe hack to change ordering
dd <- dd %>% mutate(country = toupper(country))
dd <- dd %>% mutate(region = case_when(
  country=="BANGLADESH" | country=="INDIA"|
    country=="NEPAL" | country=="PAKISTAN"|
    country=="PHILIPPINES"                   ~ "South Asia", 
  country=="KENYA"|
    country=="GHANA"|
    country=="BURKINA FASO"|
    country=="GUINEA-BISSAU"|
    country=="MALAWI"|
    country=="SOUTH AFRICA"|
    country=="TANZANIA, UNITED REPUBLIC OF"|
    country=="TANZANIA"|
    country=="ZIMBABWE"|
    country=="GAMBIA"                       ~ "Africa",
  country=="BELARUS"                      ~ "",
  country=="BRAZIL" | country=="GUATEMALA" |
    country=="PERU"                         ~ "Latin America",
  TRUE                                    ~ "Other"
))

dd$region <- as.character(dd$region)
dd$region <- factor(dd$region, levels=c("South Asia","Africa","Latin America",""))



dd$studycountry[dd$studycountry=="Tanzania Child 2, Tanzania"] <- "Tanzania Child 2" 

dd <- mutate(dd,
             studycountry = factor(studycountry,
                                   levels=unique(studycountry[order(region,stuntprev)]), 
                                   ordered=TRUE))

# categorize stunting prevalence
dd$stpcat <- cut(dd$stuntprev,breaks=c(0,5,10,20,30,40,50,60,100),labels=c("<5","5-10","10-20","20-30","30-40","40-50","50-60",">60"))
dd$stpcat <- factor(dd$stpcat)


#-----------------------------------
# Create a long format dataset
# for ggplot2
#-----------------------------------

# gather N measurements by month data into long format
dnsubj <- select(dd,study_id,country,studycountry,region,stuntprev,starts_with('n')) %>%
  select(-neurocog_data,-nutrition,-notes,-num_countries,-numcountry,-numsubj,-numobs,-nmeas) %>%
  gather(age,nobs,-study_id,-country,-studycountry,-region,-stuntprev) %>%
  mutate(age=as.integer(str_sub(age,2,-1)),nobs=as.integer(nobs)) %>%
  select(study_id,country,studycountry,region,stuntprev,age,nobs) %>%
  filter(age>=0 & age <=24 ) %>%
  arrange(region,stuntprev) 

# gather stunting prev by month data into long format
dstuntp <- select(dd,study_id,country,studycountry,starts_with('stuntprev_m')) %>%
  gather(age,stp,-study_id,-country,-studycountry) %>%
  mutate(age=as.integer(str_sub(age,12,-1))) %>%
  select(study_id,country,studycountry,age,stp) %>%
  filter(age>=0 & age <=24 )

# gather meanLAZ by month data into long format
dhaz <- select(dd,study_id,country,studycountry,starts_with('meanHAZ_m')) %>%
  gather(age,haz,-study_id,-country,-studycountry) %>%
  mutate(age=as.integer(str_sub(age,10,-1))) %>%
  select(study_id,country,studycountry,age,haz) %>%
  filter(age>=0 & age <=24 )


# join the long tables together and sort countries by measure_freq and stunting prev
dim(dnsubj)
dim(dstuntp)
dp <- left_join(dnsubj,dstuntp,by=c('study_id','studycountry','age'))
dim(dp)
dp <- left_join(dp,dhaz,by=c('study_id','studycountry','age'))
dim(dp)

# categorize stunting prevalence, set stunting prevalence category estimates to missing if n<50
dp$stpcat <- cut(dp$stp,breaks=c(0,5,10,20,30,40,50,60,100),labels=c("<5","5-10","10-20","20-30","30-40","40-50","50-60",">60"))
dp$stpcat <- factor(dp$stpcat)
dp$stpcat[dp$nobs<50 | is.nan(dp$stp)] <- NA

# categorize number of observations
N_breaks <- c(1,50, 100, 250, 500, 750, 1000, 1500, 2000, 100000)
dp$ncat <- cut(dp$nobs,
               breaks=N_breaks,
               labels=c('<50','50-100','100-250','250-500','500-750','750-1000','1000-1500','1500-2000','>2000'))
dp$ncat <- factor(dp$ncat)

# categorize mean HAZ
summary(dp$haz)
dp$hazcat <- cut(dp$haz,breaks=c(-5, -3, -2.5, -2,-1.5,-1,-0.5,0,5), 
                 labels=c("<= -3","(-3,-2.5]", "(-2.5,-2]", "(-2,-1.5]", "(-1.5,-1]", "(-1,-0.5]",  "(-0.5,0]", ">0" ))
table(dp$hazcat)
dp$hazcat<- factor(dp$hazcat)
dp$hazcat[dp$nobs<50 | is.nan(dp$hazcat)] <- NA

dp$hazcatnew = as.character(dp$hazcat)
dp$hazcatnew = ifelse(is.na(dp$hazcat), "Fewer than 50\nobservations", dp$hazcatnew)
dp$hazcatnew<- factor(dp$hazcatnew, levels = c("<= -3","(-3,-2.5]",
                              "(-2.5,-2]", "(-2,-1.5]", "(-1.5,-1]", "(-1,-0.5]",
                              "(-0.5,0]", ">0", "Fewer than 50\nobservations"))


#-----------------------------------
# Basic plot schemes
#
# there is one for a heat map and 
# a second for a side bar plot
# to summarize a single dimension
# (such as N or stunting prevalence)
#
# there is a little bit of 
# a trick here  to ensure that
# they have the two plots render
# have the same exact dimensions
# so that the line up properly in
# the grid.arrange() function.
# to do this, you need to create a 
# "ghost" legend in the side bar
# using a fake fill.  It uses the 
# aes.overide arguments to make 
# everything white so that you can't
# see it.
#-----------------------------------

#define a color for fonts
textcol <- "grey20"

# heat map plot scheme
hm <- ggplot(dp,aes(x=age,y=studycountry)) +
  # facet over measurement frequency
  facet_grid(region~.,scales='free_y',space='free_y') +
  #add border white colour of line thickness 0.25
  geom_tile(colour="white",size=0.25)+
  #remove extra space
  scale_y_discrete(expand=c(0,0))+
  scale_x_continuous(expand=c(0,0),
                     breaks=0:24,labels=0:24)+
  #one unit on x-axis is equal to one unit on y-axis.
  #equal aspect ratio x and y axis
  # coord_equal()+
  #set base size for all font elements
  theme_grey(base_size=10)+
  #theme options
  theme(
    # legend options
    legend.title=element_text(color=textcol,size=8),
    #reduce/remove legend margin
    legend.margin = margin(grid::unit(0.1,"cm")),
    #change legend text properties
    legend.text=element_text(colour=textcol,size=7,face="bold"),
    #change legend key height
    legend.key.height=grid::unit(0.2,"cm"),
    #set a slim legend
    legend.key.width=grid::unit(1,"cm"),
    #move legend to the bottom
    legend.position = "bottom",
    #set x axis text size and colour
    axis.text.x=element_text(size=8,colour=textcol,angle=0,vjust=0.5),
    #set y axis text colour and adjust vertical justification
    axis.text.y=element_text(size=8,vjust = 0.2,colour=textcol),
    #change axis ticks thickness
    axis.ticks=element_line(size=0.4),
    # axis.ticks.x=element_blank(),
    #change title font, size, colour and justification
    plot.title=element_text(colour=textcol,hjust=0,size=12,face="bold"),
    #format facet labels
    strip.text.x = element_text(size=10),
    strip.text.y = element_text(angle=270,size=10),
    #remove plot background
    plot.background=element_blank(),
    #remove plot border
    panel.border=element_blank()
    
    #remove plot margins
    # plot.margin=margin(grid::unit(1,"cm"))
  )


# side bar plot scheme
sidebar <- ggplot(data = dd, aes(x = studycountry)) + 
  geom_bar(stat = "identity") +
  coord_flip() + 
  facet_grid(region~.,scales='free_y',space='free_y') +
  #remove extra space
  scale_x_discrete(expand=c(0,0)) +
  scale_fill_manual(values=rep('gray70',7),na.value="grey90",
                    guide=guide_legend(title="",title.hjust = 0.5,
                                       label.position="bottom",label.hjust=0.5,nrow=1,
                                       override.aes = list(color = "white", fill="white"))) +
  theme_grey(base_size=10) +
  theme(
    # legend options
    # has to be the exact same format as for the other panel (for correct alignment)
    legend.title=element_text(color=textcol,size=8),
    #reduce/remove legend margin
    legend.margin = margin(grid::unit(0.1,"cm")),
    #change legend text properties
    legend.text=element_text(colour=NA,size=7,face="bold"),
    #change legend key height
    legend.key.height=grid::unit(0.2,"cm"),
    #set a slim legend
    legend.key.width=grid::unit(0.2,"cm"),
    #move legend to the bottom
    legend.position = "bottom",
    # remove study labels
    axis.title.y = element_blank(), 
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    #adjust facet labels
    strip.text.x = element_blank(),
    strip.text.y = element_blank(),
    # x-axis labels
    axis.title.x = element_text(size=10),
    # title has to be the exact same format as for the other panel (for correct alignment)
    plot.title=element_text(colour=textcol,hjust=0,size=12,face="bold"),
    # remove grid lines
    panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
    panel.background = element_blank()
    
  )



#-----------------------------------
# STUNTING PREVALENCE HEAT MAP
#-----------------------------------
# heat map
viridis_cols = c(viridis(
  n = length(levels(dp$hazcatnew)) - 1,
  alpha = 1,
  begin = 0,
  end = 0.8,
  direction = -1,
  option = "C"
  ),
  "grey90")

stphm <- hm +
  #aes(fill=hazcat) +
  # labs(x="Age in months",y="",title="Mean height-for-age Z-score by month of age") +
  labs(x="Age in months",y="",title="b") +
  aes(fill = hazcatnew) +
  labs(x = "Age in months", y = "", title = "Mean height-for-age Z-score by month of age") +  
  
  scale_fill_manual(guide=guide_legend(title="Mean HAZ",title.vjust = 1,
                                       label.position="bottom",label.hjust=0.1,nrow=1),
                    values = viridis_cols) 

#-----------------------------------
# number of obs side bar plot
#-----------------------------------
nbar <- sidebar +
  aes(y=nmeas/1000,fill=stpcat) +
  labs(x = "",y="Sample size (1000s)",title="c") +
  scale_y_continuous(expand=c(0,0),limits=c(0,125),
                     breaks=seq(0,125,by=25),labels=seq(0,125,by=25)) +
  geom_hline(yintercept = seq(0,125,by=25),color='white',size=0.3)

#-----------------------------------
# stunting prevalence side bar plot
#-----------------------------------
stpbar <- sidebar +
  aes(y=stuntprev,fill=stpcat) +
  # labs(x = "",y="Overall Prevalence (%)",title="Stunting") +
  labs(x = "",y="Stunting Prevalence (%)",title="d") +
  scale_y_continuous(expand=c(0,0),limits=c(0,70),
                     breaks=seq(0,70,by=10),labels=seq(0,70,by=10)) +
  geom_hline(yintercept = seq(0,70,by=10),color='white',size=0.3)

#-----------------------------------
# n by age top plot 
#-----------------------------------
nagebar <- ggplot(dp, aes(y = nobs/1000, x = age)) +
  geom_bar(stat = "identity", fill='gray70') +  
  scale_x_continuous(breaks = seq(1,24,1), labels = seq(1,24,1)) +
  theme(
    # make background white
    panel.background = element_blank(),
    # remove major grid lines
    panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
    plot.title=element_text(colour=textcol,hjust=0.04,size=12,face="bold"),
    # remove x axis ticks
    axis.title.x=element_blank(),
    axis.text.x=element_blank(),
    axis.ticks.x=element_blank(),
    panel.border = element_blank(),
    axis.title.y = element_text(size=10)
  ) +
  ylab("Sample size (1000s)") + xlab("") +
  geom_hline(yintercept = seq(0,80,by=10),color='white',size=0.3) +
  ggtitle("a")

# add margin around plots
stphm = stphm + theme(plot.margin = unit(c(0,0.25,0.25,0.25), "cm"))
stpbar = stpbar + theme(plot.margin = unit(c(0,0.3,0.25,0.1), "cm"))
nbar = nbar + theme(plot.margin = unit(c(0,0.25,0.25,0.1), "cm"))
nagebar = nagebar + theme(plot.margin = unit(c(0.25,0.125,0,3.5), "cm"))
empty <- grid::textGrob("") 

# arrange components into single plot
stpgrid <- grid.arrange(nagebar, empty, empty,
                        stphm, nbar, stpbar,nrow = 2, ncol = 3,
                        heights = c(25,100),
                        widths=c(100,20,20))

# define standardized plot names
stpgrid_name = create_name(
  outcome = "stunting and laz" ,
  cutoff = 2,
  measure = "heatmap",
  population = "overall",
  location = "",
  age = "All ages",
  analysis = "primary"
)

# save plot and underlying data
ggsave(filename=paste0(fig_dir, "stunting/fig-",stpgrid_name,".pdf"),
       plot = stpgrid,device='pdf',width=12,height=9)
saveRDS(list(dd = dd,
             dp = dp), 
        file=paste0(figdata_dir, "figdata-",stpgrid_name,".RDS"))

