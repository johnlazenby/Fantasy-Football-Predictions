import pandas as pd
from selenium import webdriver
import time

driver = webdriver.Chrome('') #insert path to chromedriver
driver.get('https://fantasyfootballers.org/draftkings-fantasy-football-player-projections-tool/')

dict_of_rows = {"1":526,"2":510,"3":507,"4":472,"5":436,"6":432,"7":433,"8":432,"9":440,"10":452,"11":496}
weeks = range(1,11 + 1)
list_of_dicts = []

for week in weeks:
    driver.find_element_by_xpath('//*[@id="Week"]/option[text()="{}"]'.format(week)).click()
    driver.find_element_by_xpath('//*[@id="post-4168"]/div/table/tbody/tr/td[1]/form/input').click()
    time.sleep(5)
    week_rows = dict_of_rows['{}'.format(week)]
    print(week)
    print("**********************")
    for row in range(1,week_rows + 1):
        name = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[2]/a'.format(row)).text
        team = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[3]/a'.format(row)).text
        pos = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[4]'.format(row)).text
        projection = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[5]'.format(row)).text
        salary = driver.find_element_by_xpath('//*[@id="table_id"]/tbody/tr[{}]/td[6]'.format(row)).text
        row_of_data = {"week":week,"name":name,"team":team,"pos":pos,"projection":projection,"salary":salary}
        list_of_dicts.append(row_of_data)

df = pd.DataFrame(list_of_dicts)
df.to_csv("projections_2020_weeks1_11.csv")
