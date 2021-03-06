
rm(list=ls())
library(tidyverse)
library(ggthemes)

dfull <- readRDS('C:/Users/andre/Dropbox/HBGDki figures/Mortality/mortality_results_processed.rds')

levels(dfull$outcome_variable)[10] <- "mortality"



d <- dfull %>% filter(birthweight_strat=="0")






#Plot parameters
yticks <- c( 0.50, 1.00, 2.00, 4.00, 8.00)
tableau10 <- c("#1F77B4","#FF7F0E","#2CA02C","#D62728",
               "#9467BD","#8C564B","#E377C2","#7F7F7F","#BCBD22","#17BECF")
tableau11 <- c("Black","#1F77B4","#FF7F0E","#2CA02C","#D62728",
               "#9467BD","#8C564B","#E377C2","#7F7F7F","#BCBD22","#17BECF")
Ylab <- "Relative Risk"
scaleFUN <- function(x) sprintf("%.2f", x)
theme_set(theme_bw())


clean_nmeans<-function(nmeas){
  nmeas <- round(nmeas/1000)
  nmeas.f <- paste0("N=",nmeas,"K children")
  return(nmeas.f)
}

clean_agecat<-function(agecat){
  agecat <- as.character(agecat)
  agecat <- gsub("months","mo.", agecat)
  agecat <- factor(agecat, levels=unique(agecat))
  return(agecat)
}


d <- d %>% filter(intervention_level==1) %>% 
  filter(unadjusted==0 | intervention_variable=="ever_wasted024" | intervention_variable=="ever_sstunted024") %>%
  filter(pooled == 1)
d$pooled <- factor(d$pooled)
d <- droplevels(d)

d$outcome_variable <- factor(d$outcome_variable, levels=c("mortality","pers_wasted624","co_occurence"))
levels(d$outcome_variable) <- c("Mortality","Persistently wasted from 6-24 months","Wasted and stunted at 18 months")


d$RFlabel <- NA
d$RFlabel[d$intervention_variable=="ever_wasted06"] <- "Wasted under 6mo" 
d$RFlabel[d$intervention_variable=="ever_wasted024"] <- "Wasted under 24mo" 
d$RFlabel[d$intervention_variable=="ever_swasted06"] <-  "Severely wasted under 6mo" 
d$RFlabel[d$intervention_variable=="ever_swasted024"] <-  "Severely wasted under 24mo" 
d$RFlabel[d$intervention_variable=="pers_wasted06"] <- "Persistently wasted under 6mo"
d$RFlabel[d$intervention_variable=="ever_stunted06"] <- "Stunted under 6mo" 
d$RFlabel[d$intervention_variable=="ever_sstunted06"] <- "Severely stunted under 6mo" 
d$RFlabel[d$intervention_variable=="pers_wasted024"] <- "Persistently wasted under 24mo"
d$RFlabel[d$intervention_variable=="ever_stunted024"] <- "Stunted under 24mo" 
d$RFlabel[d$intervention_variable=="ever_sstunted024"] <- "Severely stunted under 24mo"
d$RFlabel[d$intervention_variable=="ever_wasted06_noBW"] <- "Wasted under 6mo, excluding birth"  
d$RFlabel[d$intervention_variable=="ever_swasted06_noBW"] <-  "Severely wasted under 6mo, excluding birth"  
d$RFlabel[d$intervention_variable=="ever_wasted024_noBW"] <-  "Wasted under\n24mo, excluding birth"  
d$RFlabel[d$intervention_variable=="ever_swasted024_noBW"] <-  "Severely wasted under 24mo, excluding birth"  
d$RFlabel[d$intervention_variable=="ever_underweight06"] <-  "Underweight under 6mo"
d$RFlabel[d$intervention_variable=="ever_sunderweight06"] <-  "Severely underweight under 6mo"
d$RFlabel[d$intervention_variable=="ever_underweight024"] <-  "Underweight under 24mo"
d$RFlabel[d$intervention_variable=="ever_sunderweight024"] <-  "Severely underweight under 24mo"
d$RFlabel[d$intervention_variable=="ever_co06"] <-  "Wasted and stunted under 6mo"
d$RFlabel[d$intervention_variable=="ever_co024"] <-  "Wasted and stunted under 24mo"

d$Measure <- NA
d$Measure <- ifelse(grepl("nderweight",d$RFlabel),"Underweight",d$Measure)
d$Measure <- ifelse(grepl("tunted",d$RFlabel),"Stunted",d$Measure)
d$Measure <- ifelse(grepl("asted",d$RFlabel),"Wasted",d$Measure)
d$Measure <- ifelse(grepl("ersistently wasted",d$RFlabel),"Persistently wasted",d$Measure)
d$Measure <- ifelse(grepl("asted and stunted",d$RFlabel),"Wasted and stunted",d$Measure)
table(d$Measure)


d$severe <- factor(ifelse(grepl("evere",d$RFlabel),"Yes","No"))
table(d$severe)

d$agerange <- factor(ifelse(grepl("24",d$RFlabel),"0-24 months","0-6 months"))
table(d$agerange)

d$type <- paste0(d$severe, " ", d$agerange)
d$type <- factor(d$type, levels=c("No 0-6 months", "Yes 0-6 months", "No 0-24 months", "Yes 0-24 months"))

d$BW <- factor(ifelse(grepl("birth",d$RFlabel),"*",""))
table(d$BW)

d$intervention_variable <- factor(d$RFlabel)



i<- levels(d$outcome_variable)[1]

  d2 <- d %>% filter(outcome_variable==i) %>% filter(Region=="Pooled")
  d2<-droplevels(d2)
  
  d2$intervention_variable <- as.character(d2$intervention_variable)
  d2 <- d2 %>% arrange(RR)
  d2$intervention_variable <- factor(d2$intervention_variable, levels=unique(d2$intervention_variable))

p <- ggplot(d2, aes(x=as.numeric(intervention_variable))) +
    geom_point(aes(y=RR, color=Measure, shape=factor(type)), size=4, stroke = 1.5) +
    geom_linerange(aes(ymin=RR.CI1, ymax=RR.CI2, color=Measure)) +
    geom_text(aes(x=as.numeric(intervention_variable)+0.1, y=RR+0.1, label=BW), size=8) +
    labs(x = "", y = "Adjusted Relative Risk") +
    geom_hline(yintercept = 1) +
    scale_y_continuous(breaks=yticks, trans='log10', labels=scaleFUN) +
    scale_colour_manual(values=tableau10[c(4,1,3,2,7)]) +
    scale_fill_manual(values=tableau10[c(4,1,3,2,7)]) +
    #scale_fill_manual(values=tableau11[c(5,1)]) +
    scale_size_manual(values=c(4,5)) +
    scale_shape_manual(name = "Shape", 
                       labels = c("Moderate 0-6 months", 
                                  "Severe 0-6 months",
                                  "Moderate 0-24 months", 
                                  "Severe 0-24 months"),
                       values=c(16,21,17,24)) +
    theme(plot.title = element_text(hjust = 0.5),
          strip.background = element_blank(),
          legend.position="none",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          #strip.text.x = element_text(size=12),
          #axis.text.x = element_text(size=12, angle = 45, hjust = 1),
          text = element_text(size=16)) +
    ggtitle(paste0("")) + coord_cartesian(ylim=c(1,8))
p
ggsave(p, file="figures/mortality/Mortality_plot.png",  width=6, height=5.2)


table(d2$intervention_variable)
d2<-d2[!grepl("excluding",d2$intervention_variable),]
d2 <- d2 %>% filter(agecat=="0-6 months\ncumulative incidence")
d2 <- droplevels(d2)
d3 <- d2

p <- ggplot(d2, aes(x=as.numeric(intervention_variable))) +
  geom_point(aes(y=RR, color=Measure, shape=factor(type)), size=4, stroke = 1.5) +
  geom_linerange(aes(ymin=RR.CI1, ymax=RR.CI2, color=Measure)) +
  geom_text(aes(x=as.numeric(intervention_variable)+0.1, y=RR+0.1, label=BW), size=8) +
  labs(x = "", y = "Adjusted Relative Risk") +
  geom_hline(yintercept = 1) +
  scale_y_continuous(breaks=yticks, trans='log10', labels=scaleFUN) +
  scale_colour_manual(values=tableau10[c(4,1,3,2,7)]) +
  scale_fill_manual(values=tableau10[c(4,1,3,2,7)]) +
  scale_size_manual(values=c(4,5)) +
  scale_shape_manual(name = "Shape", 
                     labels = c("Moderate 0-6 months", 
                                "Severe 0-6 months",
                                "Moderate 0-24 months", 
                                "Severe 0-24 months"),
                     values=c(16,21,17,24)) +
  theme(plot.title = element_text(hjust = 0.5),
        strip.background = element_blank(),
        legend.position="none",
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        text = element_text(size=16)) +
  ggtitle(paste0("")) + coord_cartesian(ylim=c(1,8))
p

ggsave(p, file=paste0(here::here(),"/figures/risk factor/Mortality_plot_u6_faltering.png"),  width=6, height=5.2)


#Simplified plot with no colors but with labels
d4 <- d2
d4$intervention_variable <- gsub(" under 6mo","",d4$intervention_variable)
d4$intervention_variable <- gsub("Wasted and stunted","Wasted and\nstunted",d4$intervention_variable)
d4$intervention_variable <- factor(d4$intervention_variable, levels=unique(d4$intervention_variable))
p <- ggplot(d4, aes(x=intervention_variable)) +
  geom_point(aes(y=RR), size=4, stroke = 1.5) +
  geom_linerange(aes(ymin=RR.CI1, ymax=RR.CI2)) +
  geom_text(aes(x=as.numeric(intervention_variable)+0.1, y=RR+0.1, label=BW), size=8) +
  labs(x = "Measure of faltering in children under 6mo", y = "Adjusted Relative Risk") +
  geom_hline(yintercept = 1) +
  scale_y_continuous(breaks=yticks, trans='log10', labels=scaleFUN) +
  scale_fill_manual(values=tableau10[c(4,1,3,2,7)]) +
  scale_size_manual(values=c(4,5)) +
  scale_shape_manual(name = "Shape", 
                     labels = c("Moderate 0-6 months", 
                                "Severe 0-6 months",
                                "Moderate 0-24 months", 
                                "Severe 0-24 months"),
                     values=c(16,21,17,24)) +
  theme(plot.title = element_text(hjust = 0.5),
        strip.background = element_blank(),
        legend.position="none",
        strip.text.x = element_text(size=12),
        axis.text.x = element_text(size=12, angle = 15, hjust = 0.5, vjust=0.5),
        text = element_text(size=16)) +
  ggtitle(paste0("")) + coord_cartesian(ylim=c(1,8))
print(p)

ggsave(p, file=paste0(here::here(),"/figures/risk factor/Mortality_plot_u6_faltering_simp.png"),  width=10, height=5.2)





i<-levels(d$outcome_variable)[2]

d2 <- d %>% filter(outcome_variable==i)
d2<-d2[!grepl("Severely",d2$intervention_variable),]
d2<-d2[!grepl("excluding",d2$intervention_variable),]
d2<-droplevels(d2)

d2$intervention_variable <- as.character(d2$intervention_variable)
d2 <- d2 %>% arrange(RR)
d2$intervention_variable <- factor(d2$intervention_variable, levels=unique(d2$intervention_variable))

p <- ggplot(d2, aes(x=as.numeric(intervention_variable))) +
  geom_point(aes(y=RR, color=Measure, shape=factor(type)), size=4, stroke = 1.5) +
  geom_linerange(aes(ymin=RR.CI1, ymax=RR.CI2, color=Measure)) +
  geom_text(aes(x=as.numeric(intervention_variable)+0.1, y=RR+0.1, label=BW), size=8) +
  labs(x = "", y = "Adjusted Relative Risk") +
  geom_hline(yintercept = 1) +
  scale_y_continuous(breaks=yticks, trans='log10', labels=scaleFUN) +
  scale_colour_manual(values=tableau10[c(4,1,3,2,7)]) +
  scale_fill_manual(values=tableau10[c(4,1,3,2,7)]) +
  scale_size_manual(values=c(4,5)) +
  scale_shape_manual(name = "Shape", 
                     labels = c("Moderate 0-6 months", 
                                "Severe 0-6 months",
                                "Moderate 0-24 months", 
                                "Severe 0-24 months"),
                     values=c(16,21,17,24)) +
  theme(plot.title = element_text(hjust = 0.5),
        strip.background = element_blank(),
        legend.position="none",
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        text = element_text(size=16)) +
  ggtitle(paste0(""))+ coord_cartesian(ylim=c(1,8))

ggsave(p, file="figures/mortality/PersWastMorbidity_plot.png",  width=6, height=5.2)








i<-levels(d$outcome_variable)[2:3]

d2 <- d %>% filter(outcome_variable==i)
d2<-d2[!grepl("Severely",d2$intervention_variable),]
d2<-d2[!grepl("excluding",d2$intervention_variable),]
d2<-droplevels(d2)

d2$intervention_variable <- as.character(d2$intervention_variable)
d2 <- d2 %>% arrange(RR)
d2$intervention_variable <- factor(d2$intervention_variable, levels=unique(d2$intervention_variable))
d2$Measure <- factor(d2$Measure, levels=unique(d2$Measure))

d2$outcome_variable_f <- NA
d2$outcome_variable_f[d2$outcome_variable=="Persistently wasted from 6-24 months"] <- "Outcome: Persistently wasted\nfrom 6-24 months"
d2$outcome_variable_f[d2$outcome_variable=="Wasted and stunted at 18 months"] <- "Outcome: Wasted and stunted\nat 18 months"
  

p <- ggplot(d2, aes(x=Measure)) +
  geom_point(aes(y=RR, color=Measure), size=4, stroke = 1.5) +
  geom_linerange(aes(ymin=RR.CI1, ymax=RR.CI2, color=Measure)) +
  facet_wrap(~outcome_variable_f) +
  geom_text(aes(x=as.numeric(intervention_variable)+0.1, y=RR+0.1, label=BW), size=8) +
  labs(x = "Type of growth faltering occurring in children under 6 months", y = "Adjusted Relative Risk") +
  geom_hline(yintercept = 1) +
  scale_y_continuous(breaks=yticks, trans='log10', labels=scaleFUN) +
  scale_colour_manual(values=tableau10[c(1,2,4,7,3)]) +
  scale_size_manual(values=c(4,5)) +
  theme(plot.title = element_text(hjust = 0.5),
        strip.background = element_blank(),
        legend.position="none",
        #axis.title.x=element_blank(),
        #axis.text.x=element_blank(),
        #axis.ticks.x=element_blank(),
        strip.text.x = element_text(size=12),
        axis.text.x = element_text(size=12, angle = 25, hjust = 1),
        text = element_text(size=12)) +
  ggtitle(paste0("")) + coord_cartesian(ylim=c(1,8))

ggsave(p, file="figures/mortality/Morbidity_plot.png",  width=6, height=5.2)















