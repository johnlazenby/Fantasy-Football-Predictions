rm(list = ls())

library(tidyverse)
library(mltools)
library(data.table)

setwd('') #insert path to directory

df <- read.csv('scrape_predictions/projections_2020_weeks1_11.csv') %>% 
  select(-X)

#expert predictions have wrong salaries for these players. My guess is they do not account for there being multiple players
#with these names in the NFL and that fact messed up their merge.
df <- df %>% 
  filter(!(name == "Chris Thompson" & pos == "WR")) %>% 
  filter(!(name == "Ryan Griffin" & pos == "QB"))


df <- df %>% 
  group_by(week,name,team,pos,projection) %>% 
  summarize(salary = max(salary)) %>% 
  ungroup()

dfd <- read.csv("scrape_predictions/projections_2020_weeks1_11_D.csv") %>% 
  select(-X) %>% 
  mutate(team = name)

#append offense and defense projections together
df <- rbind(df,dfd) %>% 
  filter(pos != "K") %>% 
  mutate(pos = ifelse(pos == "DST","Def",pos)) %>% 
  mutate(year = 2020) %>% 
  select(-team)
  
#check one name per team-week
df %>% group_by(year,week,name) %>% 
  summarize(count = n()) %>% 
  arrange(-count) %>% 
  mutate(we_good = max(count) == 1) %>%
  group_by(we_good) %>% 
  summarize(count = n())

#merging on actual points for offensive players
dk <- read.csv("data/DK_combined_2017_2020_week10.csv") %>% 
  select(-X) %>% 
  #changing names so they match the names from DK available players
  separate(Name,into=c("Last","First"),sep=",") %>% 
  mutate(Name = trimws(paste(First,Last)),
         Name = ifelse(Pos == "Def",toupper(Team),Name)
  ) %>% 
  select(Week,Year,Name,Pos,DK.salary,DK.points)

#throw out WR "Thompson, Chris". duplicate name as the RB who is a good player. WR is not a good player.
#throw out QB "Griffin, Ryan" for the same reason.

dk <- dk %>% 
  filter(!(Name == "Chris Thompson" & Pos == "WR")) %>% 
  filter(!(Name == "Ryan Griffin" & Pos == "QB"))

#checking for duplicates
dk %>% group_by(Year,Week,Name) %>% 
  summarize(count = n()) %>% 
  mutate(we_good = max(count) == 1) %>%
  group_by(we_good) %>% 
  summarize(count = n())

#renaming columns for merge
dk %>% colnames()
dk <- dk %>% 
  rename(week = Week,
         year = Year,
         salary2 = DK.salary,
         name = Name,
         pos = Pos
         ) %>% 
  select(week,year,name,DK.points,salary2)

#correcting names and positions for clean merge
df <- df %>% 
  mutate(name = toupper(name)) %>% 
  mutate(name = gsub(" [I]+$","",name)) %>% 
  mutate(name = gsub(" JR.","",name)) %>% 
  mutate(name = gsub(" SR.","",name)) %>% 
  mutate(name = gsub("D.J.","DJ",name)) %>% 
  mutate(name = gsub("K.J.","KJ",name)) %>% 
  mutate(name = ifelse(name == "WILL FULLER V","WILL FULLER",name),
         name = ifelse(name == "WILLIE SNEAD IV","WILLIE SNEAD",name),
         name = ifelse(name == "TY JOHNSON","TYRON JOHNSON",name)) %>% 
  mutate(name = ifelse(pos == "DST",toupper(team),name),
         name = ifelse(name == "GB","GNB",name),
         name = ifelse(name == "LV","LVR",name),
         name = ifelse(name == "NO","NOR",name),
         name = ifelse(name == "JAX","JAC",name),
         name = ifelse(name == "SF","SFO",name),
         name = ifelse(name == "TB","TAM",name),
         name = ifelse(name == "KC","KAN",name),
         name = ifelse(name == "NE","NWE",name)
  )

#more corrections for clean merge
dk <- dk %>% 
  mutate(name = toupper(name)) %>% 
  mutate(name = gsub(" [I]+$","",name)) %>% 
  mutate(name = ifelse(name == "D.K. METCALF","DK METCALF",name),
         name = ifelse(name == "Richie James","Richie James Jr.",name),
         name = ifelse(name == "D.J. CHARK","DJ CHARK",name),
         name = ifelse(name == "WILL FULLER V","WILL FULLER",name),
         name = ifelse(name == "SCOTT MILLER","SCOTTY MILLER",name)
         ) %>% 
  mutate(name = gsub(" JR.","",name)) %>% 
  mutate(name = gsub("D.J.","DJ",name))

dim(dk)
dim(df)
#merge on week-year-name
merged <- merge(dk,df,by = c("name","year","week"),all.x = TRUE)
dim(merged)

#drop those that did not merge (missing projection and in 2020)
merged <- merged %>% 
  filter(!(is.na(projection) & year == 2020))

#76 salary conflicts. Use salary2
merged %>% 
  filter(year == 2020) %>% 
  mutate(test = salary == salary2) %>% 
  filter(test == FALSE)

merged <- merged %>% 
  mutate(salary = salary2) %>% 
  select(-salary2)

#drop those missing salary in 2020
merged <- merged %>% 
  filter(!(is.na(salary) & year == 2020))

merged$year %>% table()

#keep only 2020
merged <- merged %>% 
  filter(year == 2020)

#rename and one hot encode so its easy to plug into Julia
merged <- merged %>% 
rename(DKSalary = salary,
       DKP = DK.points,
       Pos = pos) %>% 
  #change full back to running back
  mutate(Pos = ifelse(Pos == "FB","RB",Pos)) %>% 
  mutate(Pos = as.factor(Pos)) %>% 
  #one hot encode position column in order to work with Julia optimization
  data.table() %>% 
  filter(!is.na(DKSalary)) %>% 
  filter(DKSalary != 0) %>% 
  one_hot()

#write to csv
write.csv(merged,"output/expert_projections_with_DKP_2020.csv")
