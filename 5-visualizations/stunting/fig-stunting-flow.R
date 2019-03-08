#-----------------------------------------
# Stunting flow chart
#-----------------------------------------
rm(list=ls())
source(paste0(here::here(), "/0-config.R"))



# load fake data
stunt_data = readRDS(paste0(res_dir, "fakeflow.RDS"))
stunt_pool = readRDS(paste0(res_dir, "fakeflow_pooled.RDS"))

# load real data
stunt_data = readRDS(paste0(res_dir, "stuntflow.RDS"))
stunt_pool = readRDS(paste0(res_dir, "stuntflow_pooled.RDS"))

plot_data = stunt_data %>%
  mutate(classif = case_when(
    never_stunted == 1 ~ "Never stunted",
    prev_stunted == 1 ~ "Recovered",
    still_stunted == 1 ~ "Still stunted",
    newly_stunted == 1 ~ "Newly stunted",
    relapse == 1 ~ "Stunting relapse"

  )) %>%
  select(subjid, agecat, classif) %>%
  mutate(freq = 1) %>%
  mutate(classif = factor(classif, levels = c("Never stunted",
                                              "Recovered",
                                              "Stunting relapse",
                                              "Newly stunted",
                                              "Still stunted"
                                              )))


mycols = c("#11466B", tableau10[1], tableau10[4], "#FB5D5E", "#811818")
# mycols = c("#11466B", tableau10[1], tableau10[4], tableau10[2], "#811818")

#-----------------------------------------
# Alluvial flow plot
#-----------------------------------------
# flow_plot = ggplot(plot_data,
#        aes(x = agecat,  
#            alluvium = subjid,
#            stratum = classif,
#            fill = classif, 
#            label = classif)) +
#   geom_flow(stat = "alluvium", lode.guidance = "rightleft",
#             color = "darkgray") +
#   geom_stratum()  +
#   scale_fill_manual("", values = mycols) +
#   theme(legend.position = "bottom") +
#   xlab("Child age") + ylab("Number of children")
# 
# #ggsave(flow_plot, file="figures/stunting/pool_flow_fake.png", width=10, height=5)
# ggsave(flow_plot, file="figures/stunting/pool_flow.png", width=10, height=5)

#-----------------------------------------
# bar graphs without alluvival flow between each child
#-----------------------------------------
plot_data_pooled = stunt_pool %>%
  rename(classif = label) %>%
  select(agecat, classif, est) %>%
  mutate(classif = ifelse(classif=="Previously stunted", "Recovered", classif)) %>%
  mutate(classif = factor(classif, levels = c("Never stunted", 
                                              "Recovered",
                                              "Stunting relapse",
                                              "Newly stunted",
                                              "Still stunted"
  )))


bar_flow_plot = ggplot(plot_data_pooled) +
  geom_bar(aes(x = agecat, y = est, fill = classif), stat="identity", width=0.5) +
  scale_fill_manual("", values = mycols) +
  theme(legend.position = "bottom") +
  xlab("Child age") + ylab("Percentage of children")

ggsave(bar_flow_plot, file="figures/stunting/pool_flow_bar.png", width=10, height=5)

# old code from draft with individual level data, no RMA 
# age_classif_totals = plot_data %>%
#   group_by(agecat, classif) %>%
#   summarise(n = sum(freq))
# 
# age_totals = plot_data %>%
#   group_by(agecat) %>%
#   summarise(tot = sum(freq))
# 
# bar_plot_data = full_join(age_classif_totals, age_totals, by = c("agecat"))
# 
# bar_plot_data = bar_plot_data %>% mutate(percent = n/tot * 100)

# ggplot(bar_plot_data) +
#   geom_bar(aes(x = agecat, y = percent, fill = classif), stat="identity", width=0.5) +
#   scale_fill_manual("", values = mycols) +
#   theme(legend.position = "bottom") +
#   xlab("Child age") + ylab("Percentage of children")
# 

# ggsave(bar_plot, file="figures/stunting/pool_bar.png", width=10, height=5)



