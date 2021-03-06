



summary.prev.whz <- function(d, severe.wasted=F){
  
  # take mean of multiple measurements within age window
  dmn <- d %>%
    filter(!is.na(agecat)) %>%
    group_by(studyid,country,subjid,agecat) %>%
    summarise(whz=mean(whz, na.rm=T)) %>%
    mutate(wasted=ifelse(whz< -2, 1,0),swasted=ifelse(whz< -3, 1,0))
  
  if(severe.wasted==T){
    dmn$wasted <- dmn$swasted
  }
  
  # count measurements per study by age
  # exclude time points if number of measurements per age
  # in a study is <50
  prev.data = dmn %>%
    filter(!is.na(agecat)) %>%
    group_by(studyid,country,agecat) %>%
    summarise(nmeas=sum(!is.na(whz)),
              prev=mean(wasted),
              nxprev=sum(wasted==1)) %>%
    filter(nmeas>=50) 
  
  prev.data <- droplevels(prev.data)
  
  
  # cohort specific results
  prev.cohort=lapply((levels(prev.data$agecat)),function(x) 
    fit.escalc(data=prev.data,ni="nmeas", xi="nxprev",age=x,meas="PLO"))
  prev.cohort=as.data.frame(rbindlist(prev.cohort))
  prev.cohort=cohort.format(prev.cohort,y=prev.cohort$yi,
                            lab=  levels(prev.data$agecat))
  
  # estimate random effects, format results
  prev.res=lapply((levels(prev.data$agecat)),function(x) 
    fit.rma(data=prev.data,ni="nmeas", xi="nxprev",age=x,measure="PLO",nlab="children"))
  prev.res=as.data.frame(rbindlist(prev.res))
  prev.res[,4]=as.numeric(prev.res[,4])
  prev.res[,6]=as.numeric(prev.res[,6])
  prev.res[,7]=as.numeric(prev.res[,7])
  prev.res = prev.res %>%
    mutate(est=est*100,lb=lb*100,ub=ub*100)
  prev.res$agecat=factor(prev.res$agecat,levels=levels(prev.data$agecat))
  prev.res$ptest.f=sprintf("%0.0f",prev.res$est)
  
  
  # estimate random effects in birth cohorts only
  prev.res.birthcohorts=NULL
  if("Birth" %in% unique(prev.data$agecat)){
    birthcohorts<-prev.data$studyid[prev.data$agecat=="Birth"]
    prev.res.birthcohorts=lapply((levels(prev.data$agecat)),function(x) 
      fit.rma(data=prev.data[prev.data$studyid %in% birthcohorts, ],ni="nmeas", xi="nxprev",age=x,measure="PLO",nlab="children"))
    prev.res.birthcohorts=as.data.frame(rbindlist(prev.res.birthcohorts))
    
    prev.res.birthcohorts[,4]=as.numeric(prev.res.birthcohorts[,4])
    prev.res.birthcohorts[,6]=as.numeric(prev.res.birthcohorts[,6])
    prev.res.birthcohorts[,7]=as.numeric(prev.res.birthcohorts[,7])
    
    prev.res.birthcohorts = prev.res.birthcohorts %>%
      mutate(est=est*100,lb=lb*100,ub=ub*100)
    prev.res.birthcohorts$agecat=factor(prev.res.birthcohorts$agecat,levels=levels(prev.data$agecat))
    prev.res.birthcohorts$ptest.f=sprintf("%0.0f",prev.res.birthcohorts$est)
  }
  return(list(prev.data=prev.data, prev.res=prev.res, prev.res.birthcohorts=prev.res.birthcohorts, prev.cohort=prev.cohort))
}



summary.ci <- function(d,  
                       agelist=list("0-3 months","3-6 months","6-9 months","9-12 months",
                                    "12-15 months","15-18 months","18-21 months","21-24 months"), severe.wasted = F){
  cutoff <- ifelse(severe.wasted,-3,-2)
  
  # identify ever wasted children
  evs = d %>%
    filter(!is.na(agecat) & !is.na(whz)) %>%
    group_by(studyid,country,subjid) %>%
    arrange(studyid,subjid) %>%
    #create variable with minwhz by age category, cumulatively
    mutate(minwhz=ifelse(agecat=="0-3 months",min(whz[agecat=="0-3 months"]),
                         ifelse(agecat=="3-6 months",min(whz[agecat=="0-3 months" | agecat=="3-6 months"]),
                                ifelse(agecat=="6-9 months",min(whz[agecat=="0-3 months" | agecat=="3-6 months"|agecat=="6-9 months"]),
                                       ifelse(agecat=="9-12 months",min(whz[agecat=="0-3 months" | agecat=="3-6 months"|agecat=="6-9 months"|agecat=="9-12 months"]),
                                              ifelse(agecat=="12-15 months",min(whz[agecat=="0-3 months" | agecat=="3-6 months"|agecat=="6-9 months"|agecat=="9-12 months"|agecat=="12-15 months"]),
                                                     ifelse(agecat=="15-18 months",min(whz[agecat=="0-3 months" | agecat=="3-6 months"|agecat=="6-9 months"|agecat=="9-12 months"|agecat=="12-15 months"|agecat=="15-18 months"]),
                                                            ifelse(agecat=="18-21 months",min(whz[agecat=="0-3 months" | agecat=="3-6 months"|agecat=="6-9 months"|agecat=="9-12 months"|agecat=="12-15 months"|agecat=="15-18 months"|agecat=="18-21 months"]),
                                                                   ifelse(agecat=="21-24 months",min(whz[agecat=="0-3 months" | agecat=="3-6 months"|agecat=="6-9 months"|agecat=="9-12 months"|agecat=="12-15 months"|agecat=="15-18 months"|agecat=="18-21 months"|agecat=="21-24 months"]),
                                                                          min(whz)))))))))) %>%
    # create indicator for whether the child was ever wasted
    # by age category
    group_by(studyid,country,agecat,subjid) %>%
    summarise(minwhz=min(minwhz)) %>%
    mutate(ever_wasted=ifelse(minwhz< cutoff,1,0))
  
  
  # count incident cases per study by age
  # exclude time points if number of measurements per age
  # in a study is <50  
  cuminc.data= evs%>%
    group_by(studyid,country,agecat) %>%
    summarise(
      nchild=length(unique(subjid)),
      nstudy=length(unique(studyid)),
      ncases=sum(ever_wasted),
      N=sum(length(ever_wasted))) %>%
    filter(N>=5)
  
  cuminc.data <- droplevels(cuminc.data)
  agelist <- agelist[agelist %in% levels(cuminc.data$agecat)]
  
  if(class(agelist)!="list"){
    agelist=list(agelist)
  }
  
  # cohort specific results
  ci.cohort=lapply(agelist,function(x) 
    fit.escalc(data=cuminc.data,ni="N", xi="ncases",age=x,meas="PLO"))
  ci.cohort=as.data.frame(do.call(rbind, ci.cohort))
  ci.cohort=cohort.format(ci.cohort,y=ci.cohort$yi,
                          lab=  agelist)
  
  # estimate random effects, format results
  ci.res=lapply((agelist),function(x)
    fit.rma(data=cuminc.data,ni="N", xi="ncases",age=x,measure="PLO",nlab=" measurements"))
  ci.res=as.data.frame(rbindlist(ci.res))
  ci.res[,4]=as.numeric(ci.res[,4])
  ci.res[,6]=as.numeric(ci.res[,6])
  ci.res[,7]=as.numeric(ci.res[,7])
  ci.res = ci.res %>%
    mutate(est=est*100, lb=lb*100, ub=ub*100)
  ci.res$ptest.f=sprintf("%0.0f",ci.res$est)
  
  
  return(list(cuminc.data=cuminc.data, ci.res=ci.res, ci.cohort=ci.cohort))
}




summary.whz <- function(d){
  
  # take mean of multiple measurements within age window
  dmn <- d %>%
    filter(!is.na(agecat)) %>%
    group_by(studyid,country,subjid,agecat) %>%
    summarise(whz=mean(whz, na.rm=T))
  
  # count measurements per study by age
  # exclude time points if number of measurements per age
  # in a study is <50
  whz.data = dmn %>%
    filter(!is.na(agecat)) %>%
    group_by(studyid,country,agecat) %>%
    summarise(nmeas=sum(!is.na(whz)),
              meanwhz=mean(whz),
              varwhz=var(whz)) %>%
    filter(nmeas>=50) 
  
  whz.data <- droplevels(whz.data)
  
  # cohort specific results
  whz.cohort=lapply((levels(whz.data$agecat)),function(x) 
    fit.escalc.cont(data=whz.data,yi="meanwhz", vi="varwhz",age=x))
  whz.cohort=as.data.frame(rbindlist(whz.cohort))
  whz.cohort=cohort.format(whz.cohort,y=whz.cohort$yi,
                           lab=  levels(whz.data$agecat), est="mean")
  
  
  # estimate random effects, format results
  whz.res=lapply((levels(whz.data$agecat)),function(x) 
    fit.cont.rma(data=whz.data, ni="nmeas", yi="meanwhz", vi="varwhz", nlab="children",age=x))
  whz.res=as.data.frame(rbindlist(whz.res))
  whz.res[,4]=as.numeric(whz.res[,4])
  whz.res[,6]=as.numeric(whz.res[,6])
  whz.res[,7]=as.numeric(whz.res[,7])
  whz.res$agecat=factor(whz.res$agecat,levels=levels(whz.data$agecat))
  whz.res$ptest.f=sprintf("%0.0f",whz.res$est)
  
  
  return(list(whz.data=whz.data, whz.res=whz.res, whz.cohort=whz.cohort))
}





summary.incprop <- function(d, recovery=F, severe.wasted=F, agelist=list("0-3 months","3-6 months","6-9 months","9-12 months","12-15 months","15-18 months","18-21 months","21-24 months")){
  
  if(recovery==T){
    d$wast_inc <- d$wast_rec
  }
  if(severe.wasted==T){
    d$wast_inc <- d$sevwast_inc
  }
  
  evs <- d %>%
    group_by(studyid, country, agecat, subjid) %>%
    filter(!is.na(agecat)) %>%
    summarise(numwast = sum(wast_inc, na.rm=T)) %>%
    mutate(ever_wasted = 1*(numwast>0))
  
  # count incident cases per study by age
  # exclude time points if number of measurements per age
  # in a study is <50  
  cuminc.data= evs%>%
    group_by(studyid,country,agecat) %>%
    summarise(
      nchild=length(unique(subjid)),
      nstudy=length(unique(studyid)),
      ncases=sum(ever_wasted),
      N=sum(length(ever_wasted))) %>%
    filter(N>=50)
  
  cuminc.data <- droplevels(cuminc.data)
  agelist <- agelist[agelist %in% levels(cuminc.data$agecat)]
  
  if(class(agelist)!="list"){
    agelist=list(agelist)
  }
  
  # cohort specific results
  ci.cohort=lapply(agelist,function(x) 
    fit.escalc(data=cuminc.data,ni="N", xi="ncases",age=x,meas="PLO"))
  ci.cohort=as.data.frame(do.call(rbind, ci.cohort))
  ci.cohort=cohort.format(ci.cohort,y=ci.cohort$yi,
                          lab=  agelist)
  
  
  #fit.rma(data=cuminc.data,ni="N", xi="ncases",age="0-3 months",measure="PLO",nlab=" measurements")
  
  # estimate random effects, format results
  ci.res=lapply((agelist),function(x)
    fit.rma(data=cuminc.data,ni="N", xi="ncases",age=x,measure="PLO",nlab=" measurements"))
  ci.res=as.data.frame(rbindlist(ci.res))
  ci.res[,4]=as.numeric(ci.res[,4])
  ci.res[,6]=as.numeric(ci.res[,6])
  ci.res[,7]=as.numeric(ci.res[,7])
  ci.res = ci.res %>%
    mutate(est=est*100, lb=lb*100, ub=ub*100)
  ci.res$ptest.f=sprintf("%0.0f",ci.res$est)
  
  
  return(list(cuminc.data=cuminc.data, ci.res=ci.res, ci.cohort=ci.cohort))
}

summary.rec60 <- function(d, length=60, agelist=as.list(c("0-3 months","3-6 months","6-9 months","9-12 months","12-15 months","15-18 months","18-21 months","21-24 months"))){
  
  if(length==30){d$wast_inc <- d$wast_rec30d}
  if(length==60){d$wast_inc <- d$wast_rec60d}
  if(length==90){d$wast_inc <- d$wast_rec90d}
  
  
  evs <- d %>%
    group_by(studyid, country, agecat, subjid) %>%
    filter(!is.na(agecat) & !is.na(wast_inc)) %>%
    summarise(numwast = sum(wast_inc, na.rm=T)) %>%
    mutate(ever_wasted = 1*(numwast>0))
  
  # count incident cases per study by age
  # exclude time points if number of measurements per age
  # in a study is <50  
  cuminc.data= evs%>%
    group_by(studyid,country,agecat) %>%
    summarise(
      nchild=length(unique(subjid)),
      nstudy=length(unique(studyid)),
      ncases=sum(ever_wasted),
      N=sum(length(ever_wasted)))# %>%
  #  filter(N>=50)
  
  
  
  # cohort specific results
  ci.cohort=lapply((agelist),function(x) 
    fit.escalc(data=cuminc.data,ni="N", xi="ncases",age=x,meas="PLO"))
  ci.cohort=as.data.frame(rbindlist(ci.cohort))
  ci.cohort=cohort.format(ci.cohort,y=ci.cohort$yi,
                          lab=  c(agelist))
  
  # estimate random effects, format results
  ci.res=lapply((agelist),function(x)
    fit.rma(data=cuminc.data,ni="N", xi="ncases",age=x,measure="PLO",nlab=" measurements"))
  ci.res=as.data.frame(rbindlist(ci.res))
  ci.res[,4]=as.numeric(ci.res[,4])
  ci.res[,6]=as.numeric(ci.res[,6])
  ci.res[,7]=as.numeric(ci.res[,7])
  ci.res = ci.res %>%
    mutate(est=est*100, lb=lb*100, ub=ub*100)
  ci.res$ptest.f=sprintf("%0.0f",ci.res$est)
  
  
  return(list(cuminc.data=cuminc.data, ci.res=ci.res, ci.cohort=ci.cohort))
  
}



summary.perswast <- function(d, agelist=c("0-3 months","3-6 months","6-9 months","9-12 months","12-15 months","15-18 months","18-21 months","21-24 months")){
  
  
  pers <- d %>% group_by(studyid, country, subjid) %>% 
    mutate(N=n()) %>% ungroup() %>%
    filter(N>=4) %>%
    group_by(studyid, country, agecat, subjid) %>%
    filter(!is.na(agecat)) %>%
    summarise(perc_wast = mean(whz < (-2)), na.rm=T) %>%
    mutate(pers_wast = 1*(perc_wast>=.5))
  
  # count incident cases per study by age
  # exclude time points if number of measurements per age
  # in a study is <50  
  pers.data= pers %>%
    group_by(studyid,country,agecat) %>%
    summarise(
      nchild=length(unique(subjid)),
      nstudy=length(unique(studyid)),
      ncases=sum(pers_wast, na.rm=T),
      N=sum(length(pers_wast))) %>%
    filter(N>=50)
  
  
  
  # cohort specific results
  pers.cohort=lapply((agelist),function(x) 
    fit.escalc(data=pers.data,ni="N", xi="ncases",age=x,meas="PLO"))
  pers.cohort=as.data.frame(rbindlist(pers.cohort))
  pers.cohort=cohort.format(pers.cohort,y=pers.cohort$yi,
                            lab=  c(agelist))
  
  # estimate random effects, format results
  pers.res=lapply((agelist),function(x)
    fit.rma(data=pers.data,ni="N", xi="ncases",age=x,measure="PLO",nlab=" measurements"))
  pers.res=as.data.frame(rbindlist(pers.res))
  pers.res[,4]=as.numeric(pers.res[,4])
  pers.res[,6]=as.numeric(pers.res[,6])
  pers.res[,7]=as.numeric(pers.res[,7])
  pers.res = pers.res %>%
    mutate(est=est*100, lb=lb*100, ub=ub*100)
  pers.res$ptest.f=sprintf("%0.0f",pers.res$est)
  
  
  return(list(pers.data=pers.data, pers.res=pers.res, pers.cohort=pers.cohort))
  
}


summary.ir <- function(d, recovery=F, sev.wasting=F, agelist=list("0-3 months","3-6 months","6-9 months","9-12 months","12-15 months","15-18 months","18-21 months","21-24 months")){
  if(recovery==T){
    d$wast_inc <- d$wast_rec
    d$pt_wast <- d$pt_wast_rec
  }
  if(sev.wasting==T){
    d$wast_inc <- d$sevwast_inc
    d$pt_wast <- d$pt_sevwast
  }
  
  # manually calculate incident cases, person-time at risk at each time point
  cruderate<-d %>%
    group_by(agecat) %>%
    summarise(inc.case=sum(wast_inc, na.rm=T),ptar=sum(pt_wast, na.rm=T)) %>%
    mutate(cruderate=inc.case/ptar)
  print(cruderate)
  
  # count incident cases and sum person time at risk per study by age
  # exclude time points if number of children per age
  # in a study is <50  
  inc.data = d %>%
    group_by(studyid,country,agecat) %>%
    summarise(ptar=sum(pt_wast, na.rm=T),
              ncase=sum(wast_inc, na.rm=T),
              nchild=length(unique(subjid)),
              nstudy=length(unique(studyid))) %>%
    filter(nchild>=5 & ptar>125 & !is.na(agecat))
  
  
  
  
  # cohort specific results
  inc.cohort=lapply((agelist),function(x) 
    fit.escalc(data=inc.data,ni="ptar", xi="ncase",age=x,meas="IR"))
  inc.cohort=as.data.frame(rbindlist(inc.cohort))
  inc.cohort$agecat=factor(inc.cohort$agecat,levels=
                             c(agelist))
  inc.cohort$yi.f=sprintf("%0.0f",inc.cohort$yi)
  inc.cohort$cohort=paste0(inc.cohort$studyid,"-",inc.cohort$country)
  inc.cohort = inc.cohort %>% mutate(region = ifelse(country=="BANGLADESH" | country=="INDIA"|
                                                       country=="NEPAL" | country=="PAKISTAN"|
                                                       country=="PHILIPPINES" ,"Asia",
                                                     ifelse(country=="BURKINA FASO"|
                                                              country=="GUINEA-BISSAU"|
                                                              country=="MALAWI"|
                                                              country=="SOUTH AFRICA"|
                                                              country=="TANZANIA, UNITED REPUBLIC OF"|
                                                              country=="ZIMBABWE"|
                                                              country=="GAMBIA","Africa",
                                                            ifelse(country=="BELARUS","Europe",
                                                                   "Latin America"))))
  
  
  # estimate random effects, format results
  ir.res=lapply((agelist),function(x)
    fit.rma(data=inc.data,ni="ptar", xi="ncase",age=x,measure="IR",nlab=" person-days"))
  ir.res=as.data.frame(rbindlist(ir.res))
  ir.res[,4]=as.numeric(ir.res[,4])
  ir.res[,6]=as.numeric(ir.res[,6])
  ir.res[,7]=as.numeric(ir.res[,7])
  
  ir.res$pt.f=paste0("N=",format(ir.res$nmeas,big.mark=",",scientific=FALSE),
                     " person-days")
  ir.res$ptest.f=sprintf("%0.02f",ir.res$est*1000)
  
  return(list(ir.data=inc.data, ir.res=ir.res, ir.cohort=inc.cohort))
}



#NOTE: need to update with correct CI and meta-analysis for medians
# summary.dur <- function(d, agelist){
#   
#   df <- d %>% 
#     group_by(studyid, region, country, agecat) %>% 
#     summarize(mean=mean(wasting_duration, na.rm=T), var=var(wasting_duration, na.rm=T), n=n()) %>%
#     mutate(se=sqrt(var), ci.lb=mean - 1.96 * se, ci.ub=mean + 1.96 * se,
#            nmeas.f=paste0("N=",n," children"))
#   
#   pooled.vel=lapply(agelist,function(x) 
#     fit.cont.rma(data=df,yi="mean", vi="var", ni="n",age=x, nlab="children"))
#   pooled.vel=as.data.frame(rbindlist(pooled.vel))
#   
#   pooled.vel$est <- as.numeric(pooled.vel$est)
#   pooled.vel <- pooled.vel %>% 
#     mutate(country_cohort="pooled", pooled=1) %>% 
#     subset(., select = -c(se)) %>%
#     rename(strata=agecat, Mean=est, N=nmeas, Lower.95.CI=lb, Upper.95.CI=ub) %>% as.data.frame()
#   print(pooled.vel)
#   
#   cohort.df <- df %>% subset(., select = c(studyid, country, region, agecat, n, nmeas.f, mean, ci.lb, ci.ub)) %>%
#     rename(N=n, Mean=mean, Lower.95.CI=ci.lb, Upper.95.CI=ci.ub,
#            strata=agecat) %>%
#     mutate(pooled=0, nstudies=1)
#   
#   return(list(dur.data=df, dur.res=pooled.vel))
# }







