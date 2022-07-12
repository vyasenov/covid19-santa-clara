rm(list=ls())
setwd('~')

# LOAD PACKAGES
library(tidyverse)
library(skimr)
library(zoo)
library(reshape2)

# LOAD DATA
data <- read_csv(file='https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv')

# SUMMARIZE DATA
str(data)
#skim(data)

# KEEP ONLY DATA FOR 2022
data <- data %>%
  filter(date > '2021-12-31')

# GENERATE NEW CASES AND MOVING AVERAGES
data <- data %>% 
  arrange(fips, date) %>%
  group_by(fips) %>%
  mutate(cases_new = cases - lag(cases),
         deaths_new = deaths - lag(deaths),
         cases_new_ma = rollmean(cases_new, 7, fill=NA),
         deaths_new_ma = rollmean(deaths_new, 7, fill=NA)) %>%
  ungroup()

# PLOT: CASES NATIONWIDE
nation <- data %>% 
  group_by(date) %>%
  summarize(cases_total = sum(cases_new_ma, na.rm = T),
            deaths_total = sum(deaths_new_ma, na.rm = T),
            cases_total_nat_pc = cases_total / (3.34*1e4),
            deaths_total_nat_pc = deaths_total / (3.34*1e4)) 

nation %>%
  ggplot(aes(x=date, y=cases_total)) +
  geom_line(size=1.1) + 
  labs(x = 'Date', y = 'New Cases')

# PLOT: CASES IN CALIFORNIA
cal <- data %>% 
  filter(state == 'California') %>%
  group_by(date) %>%
  summarize(cases_total = sum(cases_new_ma, na.rm = T),
            deaths_total = sum(deaths_new_ma, na.rm = T),
            cases_total_ca_pc = cases_total / (4*1e3),
            deaths_total_ca_pc = deaths_total / (4*1e3))

cal %>%
  ggplot(aes(x=date, y=cases_total)) +
  geom_line(size=1.1) + 
  labs(x = 'Date', y = 'New Cases')


# PLOT: CASES IN BAY AREA
bayarea <- data %>% 
  filter(state == 'California' & county %in% c("Santa Clara", "San Mateo", "San Francisco", "Alameda", "Napa", "Contra Costa", "Marin", "Solano", "Sonoma")) %>%
  group_by(date) %>%
  summarize(cases_total = sum(cases_new_ma, na.rm = T),
            deaths_total = sum(deaths_new_ma, na.rm = T),
            cases_total_ba_pc = cases_total / (7.76*1e2),
            deaths_total_ba_pc = deaths_total / (7.76*1e2)) 

bayarea %>%
  ggplot(aes(x=date, y=cases_total)) +
  geom_line(size=1.1) + 
  labs(x = 'Date', y = 'New Cases')

# PLOT: CASES IN SANTA CLARA COUNTY
sclara <- data %>% 
  filter(state == 'California' & county == "Santa Clara") %>%
  group_by(date) %>%
  summarize(cases_total = sum(cases_new_ma, na.rm = T),
            deaths_total = sum(deaths_new_ma, na.rm = T),
            cases_total_sc_pc = cases_total / (1.9*1e2),
            deaths_total_sc_pc = deaths_total / (1.9*1e2)) 

sclara %>%
  ggplot(aes(x=date, y=cases_total)) +
  geom_line(size=1.1) + 
  labs(x = 'Date', y = 'New Cases')

# PLOT: CASES PER 10,000 CAPITA - ALL COMBINED
combined <- left_join(nation,cal, by='date')
combined <- left_join(combined,bayarea, by='date')
combined <- left_join(combined,sclara, by='date')
combined <- combined %>% 
  select(date, contains('pc')) %>%
  select(!contains('death')) %>%
  filter(date > '2022-01-10')
head(combined)

combined <- melt(combined, id='date', variable.name='region', value.name='cases')

ggplot(data = combined, aes(x=date, y=cases, col=region)) +
  geom_line(size=1.05) +
  labs(x='Date', y='New Cases') +
  scale_color_discrete(labels=c('US', 'CA', 'Bay Area','Santa Clara')) +
  ggtitle('COVID-19 Cases in 2021 per 10,000 People')
ggsave(file='covid_cases.png')  
