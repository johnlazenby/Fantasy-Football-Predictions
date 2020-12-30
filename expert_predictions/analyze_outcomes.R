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
  pivot_longer(cols=roster1:roster10,names_pattern="roster([0-9]{1,2})",
                         names_to = "roster",values_to="points") %>% 
  mutate(year_week = paste(Year,"-",Week,sep = ""))

results$Year %>% table()

results %>% 
  mutate(win = points > money,
         difference = points - money) %>% 
  filter(as.numeric(roster) == 1) %>% 
  summarize(avg_diff = mean(difference),
            per_win = mean(win))
  
#average difference is much higher than the quantile predictions and percentage of wins is simmilar
