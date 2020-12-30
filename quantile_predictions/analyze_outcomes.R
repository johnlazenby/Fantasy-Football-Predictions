rm(list = ls())

library(tidyverse)

#set directory
setwd("")

#evaluating results from roster selection
results <- read.csv("output/optimization_results.csv")
results %>% colnames()
extras = 9
colnames(results) = c("Year","Week","method","money",paste("roster",c(1:(extras + 1)),sep=""))
results <- results %>%
  pivot_longer(cols=roster1:roster3,names_pattern="roster([0-9]{1,2})",
                         names_to = "roster",values_to="points") %>% 
  mutate(year_week = paste(Year,"-",Week,sep = ""))

results$Year %>% table()

#keep only best 3 rosters
rosters <- 4

#all results
results %>% 
  mutate(win = points > money,
         difference = points - money) %>% 
  group_by(method) %>%
  filter(as.numeric(roster) < rosters) %>% 
  summarize(avg_diff = mean(difference),
            per_win = mean(win)) %>% 
  arrange(-per_win)

#"training set" 2017 and 2018
results %>% 
  mutate(win = points > money,
         difference = points - money) %>% 
  group_by(method) %>%
  filter(as.numeric(roster) < rosters) %>% 
  filter((Year == 2017) | (Year == 2018)) %>% 
  summarize(avg_diff = mean(difference),
            per_win = mean(win)) %>% 
  arrange(-avg_diff)

#best results is iq10_times_09_plus_60 which is .95*10th quantile plus .05*60th quantile.
  
#"test set" 2019.
results %>% 
  mutate(win = points > money,
         difference = points - money) %>% 
  group_by(method) %>%
  #look at only best roster (roster1)
  filter(as.numeric(roster) < 2) %>% 
  filter(method == "iq10_times_09_plus_60") %>% 
  filter((Year == 2019)) %>% 
  summarize(avg_diff = mean(difference),
            per_win = mean(win)) %>% 
  arrange(-per_win)

#wins over half of the time despite having a negative average difference relative to the money line

