rm(list = ls())

library(tidyverse)
library(zoo)
library(mltools)
library(data.table)
library(cumstats)

#set directory
setwd("")

#read in data with player fantasy performance from 2017 to middle of 2020.
df <- read.csv("data/DK_combined_2017_2020_week8.csv") %>% 
  select(-X,-h.a)

#throw out WR "Thompson, Chris". duplicate name as the RB who is a good player. The WR is not a good player.
#throw out QB "Griffin, Ryan" for the same reason.

df <- df %>% 
  filter(!(Name == "Thompson, Chris" & Pos == "WR")) %>% 
  filter(!(Name == "Griffin, Ryan" & Pos == "QB"))

#verify no duplicates in year-week-name
df %>% group_by(Year,Week,Name) %>% 
  summarize(count = n()) %>% 
  mutate(we_good = max(count) == 1) %>%
  group_by(we_good) %>% 
  summarize(count = n())

##############################
#produce quantile predictions#
##############################

periods <- 8 #number of periods back by which to consider player performance

predictions_cum_season <- df %>%
  group_by(Name,Year) %>% 
  arrange(Year,Week) %>% 
  mutate(count = 1) %>% 
  mutate(count = cumsum(count)) %>% 
  mutate(max_count = max(count)) %>% 
  ungroup() %>% 
  #drop players for whom we do not have sufficient number of weeks of performance
  filter(max_count > periods) %>% 
  group_by(Name,Year) %>% 
  #create quantiles
  mutate(iqmin = lag(cummin(DK.points)),
         iq05 = lag(cumquant(DK.points,.05)),
         iq10 = lag(cumquant(DK.points,.10)),
         iq15 = lag(cumquant(DK.points,.15)),
         iq20 = lag(cumquant(DK.points,.20)),
         iq25 = lag(cumquant(DK.points,.25)),
         iq30 = lag(cumquant(DK.points,.30)),
         fq50 = lag(cumquant(DK.points,.50)),
         fq60 = lag(cumquant(DK.points,.60)),
         fq70 = lag(cumquant(DK.points,.70)),
         fq80 = lag(cumquant(DK.points,.80)),
         fq90 = lag(cumquant(DK.points,.90)),
         mean = lag(cummean(DK.points)),
         variance = lag(cumvar(DK.points))
         ) %>%
  #drop weeks that do not have 8 previous within the same season
  filter(count > periods) %>% 
  select(-count,-max_count) %>% 
  ungroup()

#create predictions as weighted combination of low quantiles and high quantiles (.05*low + .95*high)
pick_roster_cum_season <- predictions_cum_season %>% 
  mutate_at(.,vars(starts_with("iq")),list(times_09 = ~(. * .95))) %>% 
  mutate_at(.,vars(starts_with("fq")),list(times_01 = ~(. * .05))) %>% 
  mutate_at(.,vars(matches("iq[0-9]{2}_times*")),list(plus_50 = ~(. + fq50_times_01),
                                          plus_60 = ~(. + fq60_times_01),
                                          plus_70 = ~(. + fq70_times_01),
                                          plus_80 = ~(. + fq80_times_01),
                                          plus_90 = ~(. + fq90_times_01)
                                          )
  ) %>% 
  #drop extraneous columns
  select(-matches("fq[0-9]{2}"),
         -matches("_times_[0-9]{2}$"),
         -variance
         ) %>% 
  rename(DKSalary = DK.salary,
         DKP = DK.points) %>% 
  mutate(Pos = as.factor(Pos)) %>% 
  #one hot encode position column in order to work with Julia optimization
  data.table() %>% 
  filter(!is.na(DKSalary)) %>% 
  filter(DKSalary != 0) %>% 
  one_hot()

#save predictions to be used as inputs for Julia optimization
pick_roster_cum_season %>% 
  write.csv("output/quantile_pre_optimize.csv")