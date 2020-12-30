import pandas as pd
from selenium import webdriver
import time

driver = webdriver.Chrome('') #insert path to chromedriver
driver.get('https://fantasyfootballers.org/fantasy-football-team-defense-point-projections-tool/')

dict_of_rows = {"1":31,"2":31,"3":31,"4":29,"5":27,"6":27,"7":27,"8":28,"9":27,"10":27,"11":27}
weeks = range(1,11 + 1)
list_of_dicts = []

for week in weeks:
    driver.find_element_by_xpath('//*[@id="Week"]/option[text()="{}"]'.format(week)).click()
    driver.find_element_by_xpath('//*[@id="post-4186"]/div/table/tbody/tr/td[1]/form/input').click()
    time.sleep(5)
    week_rows = dict_of_rows['{}'.format(week)]
    print(week)
    print("**********************")
    for row in range(1,week_rows + 1):
        name = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[2]/a'.format(row)).text
        data_week = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[3]'.format(row)).text
        pos = "DST"
        projection = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[4]'.format(row)).text
        salary = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[5]'.format(row)).text
        row_of_data = {"week":data_week,"name":name,"pos":pos,"projection":projection,"salary":salary}
        list_of_dicts.append(row_of_data)

df = pd.DataFrame(list_of_dicts)
df.to_csv("projections_2020_weeks1_11_D.csv")
