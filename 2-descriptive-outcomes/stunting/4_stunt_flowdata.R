##########################################
# ki longitudinal manuscripts
# stunting analysis

# create indicators for newly stunted, 
# recovered, relapsed, and never stunted
##########################################

#-----------------------------------------
# Process data for stunting flow chart
#-----------------------------------------
rm(list=ls())
source(paste0(here::here(), "/0-config.R"))


load("U:/Data/Stunting/stunting_data.RData")


##########################################
# Define indicators of stunting at each time point
##########################################

# define age windows
d = d %>% 
  mutate(agecat = case_when(
    agedays==1 ~ "Birth",
    agedays>1 & agedays<=3*30.4167 ~ "0-3 months",
    agedays>3*30.4167 & agedays<=6*30.4167 ~ "3-6 months",
    agedays>6*30.4167 & agedays<=9*30.4167 ~ "6-9 months",
    agedays>9*30.4167 & agedays<=12*30.4167 ~ "9-12 months",
    agedays>12*30.4167 & agedays<=15*30.4167 ~ "12-15 months",
    agedays>15*30.4167 & agedays<=18*30.4167 ~"15-18 months",
    agedays>18*30.4167 & agedays<=21*30.4167 ~ "18-21 months",
    agedays>21*30.4167& agedays<=24*30.4167 ~ "21-24 months",
    TRUE ~ ""
  )) %>%
  mutate(agecat=factor(agecat,levels=c("Birth","0-3 months","3-6 months","6-9 months",
                                       "9-12 months","12-15 months","15-18 months",
                                       "18-21 months","21-24 months")))



# check age categories
d %>%
  group_by(agecat) %>%
  summarise(n=sum(!is.na(agedays)),
            min=min(agedays/30.4167),
            mean=mean(agedays/30.4167),
            max=max(agedays/30.4167))

# identify ever stunted children
stunt_data = d %>%
  filter(!is.na(agecat)) %>%
  group_by(studyid, country, subjid, agecat) %>%
  arrange(studyid, country, subjid) %>%
  
  summarize(minhaz = min(haz)) %>%
  
  # create indicator for whether the child 
  # was stunted in CURRENT age category
  mutate(stunted=ifelse(minhaz< -2,1,0)) %>%
  
  # create indicator for whether the child 
  # was stunted in PREVIOUS age category
  group_by(studyid, country, subjid) %>%
  mutate(minhaz_prev=ifelse(
    agecat=="Birth",NA,      
    ifelse(agecat=="0-3 months",minhaz[agecat=="Birth"],
           ifelse(agecat=="3-6 months",minhaz[agecat=="0-3 months"],
                  ifelse(agecat=="6-9 months",minhaz[agecat=="3-6 months"],
                         ifelse(agecat=="9-12 months",minhaz[agecat=="6-9 months"],
                                ifelse(agecat=="12-15 months",minhaz[agecat=="9-12 months"],
                                       ifelse(agecat=="15-18 months",minhaz[agecat=="12-15 months"],
                                              ifelse(agecat=="18-21 months",minhaz[agecat=="15-18 months"],
                                                     ifelse(agecat=="21-24 months",minhaz[agecat=="18-21 months"],
                                                            NA)))))))))) %>%
  mutate(still_stunted = ifelse(minhaz_prev < -2 & minhaz < -2, 1, 0),
         prev_stunted = ifelse(minhaz_prev < -2 & minhaz >= -2 , 1, 0)) %>%
  mutate(still_stunted = ifelse(is.na(minhaz_prev), 0, still_stunted ),
         prev_stunted = ifelse(is.na(minhaz_prev), 0, prev_stunted ))


# create indicator for whether the child 
# was NEVER stunted 
stunt_data = stunt_data %>%
  group_by(studyid, country, subjid) %>%
  mutate(cum_minhaz = cummin(minhaz)) %>%
  mutate(never_stunted = ifelse(cum_minhaz >= -2, 1, 0)) %>%
  mutate(cum_stunt = cummax(stunted)) %>%
  mutate(cum_stunt_lag = lag(cum_stunt)) %>%
  
  # create indicator for whether the child 
  # was NEWLY stunted 
  mutate(newly_stunted = ifelse(never_stunted==0 & still_stunted==0 & prev_stunted==0, 1, 0)) %>%
  mutate(newly_stunted = ifelse(agecat=="Birth" & minhaz< -2, 1, newly_stunted)) %>%
  # create indicator for whether the child 
  # had a stunting RELAPSE
  mutate(relapse = ifelse(newly_stunted==1 & cum_stunt_lag==1 & !is.na(cum_stunt_lag),1,0)) %>%
  # reassign NEWLY stunted = 0 if relapse = 1
  mutate(newly_stunted = ifelse(relapse==1 & newly_stunted==1 & !is.na(relapse),
                                0,newly_stunted)) %>%
  
  select(studyid, country, subjid, agecat, minhaz, minhaz_prev, cum_minhaz, stunted, 
         never_stunted, prev_stunted, newly_stunted, still_stunted, relapse) %>%
  
  mutate(still_stunted = ifelse(agecat=="Birth",0,still_stunted),
         prev_stunted = ifelse(agecat=="Birth",0,prev_stunted),
         relapse = ifelse(agecat=="Birth",0,relapse)) 


# Check that no child was classified in more
# than one category at any time point 
summary = stunt_data %>%
  group_by(agecat) %>%
  summarise(
    nchild=length(unique(subjid)),
    newly_stunted = sum(newly_stunted),
    still_stunted = sum(still_stunted),
    prev_stunted = sum(prev_stunted),
    never_stunted = sum(never_stunted),
    relapse = sum(relapse)) %>%
  mutate(newly_stunted = newly_stunted/nchild,
         still_stunted = still_stunted/nchild,
         prev_stunted = prev_stunted/nchild,
         never_stunted = never_stunted/nchild,
         relapse = relapse/nchild)

summary = summary %>%
  mutate(sum = still_stunted + newly_stunted + prev_stunted + never_stunted + relapse)



# aggregate data within study, country, and agecat
stunt_agg = stunt_data %>%
  group_by(studyid, country, agecat) %>%
  summarise(
    nchild=length(unique(subjid)),
    newly_stunted = sum(newly_stunted),
    still_stunted = sum(still_stunted),
    prev_stunted = sum(prev_stunted),
    never_stunted = sum(never_stunted),
    relapse = sum(relapse)) 

# estimate random effects, format results
pooled_newly = run_rma(data = stunt_agg, 
                       n_name = "nchild", 
                       x_name = "newly_stunted", 
                       label = "Newly stunted")

pooled_still = run_rma(data = stunt_agg, 
                       n_name = "nchild", 
                       x_name = "still_stunted", 
                       label = "Still stunted")

pooled_prev = run_rma(data = stunt_agg, 
                      n_name = "nchild", 
                      x_name = "prev_stunted",
                      label = "Previously stunted")

pooled_relapse = run_rma(data = stunt_agg, 
                         n_name = "nchild", 
                         x_name = "relapse",
                         label = "Stunting relapse")

pooled_never = run_rma(data = stunt_agg, 
                       n_name = "nchild", 
                       x_name = "never_stunted",
                       label = "Never stunted")

stunt_pooled = bind_rows(pooled_newly, 
                         pooled_still,
                         pooled_prev,
                         pooled_relapse,
                         pooled_never
)

saveRDS(stunt_data, file=paste0(res_dir, "stuntflow.RDS"))
saveRDS(stunt_pooled, file=paste0(res_dir, "stuntflow_pooled.RDS"))

