#!/bin/python

import cx_Oracle
import time
import os
import pandas as pd
import math

# App version
app_version = "V2"
db_edition  = "V2"

# Read the data from the CSV
input_file = os.path.join(os.path.dirname(__file__), 'customers_it.csv')
data = pd.read_csv (input_file)
df = pd.DataFrame(data)
df = df.astype(object).where(pd.notnull(df),None)

# DB connection
os.environ['TNS_ADMIN'] = '/home/ludovico_c/DK4NMBFXL9DKW0S7'
connection = cx_Oracle.connect(user='moviestream', password='Welcome#Welcome#123', dsn='DK4NMBFXL9DKW0S7_TP', cclass="EBR_Demo", purity=cx_Oracle.ATTR_PURITY_SELF)
print( "Version: " + connection.version )


cursor = connection.cursor()
try:
  cursor.execute("alter session set edition=%s" % (db_edition))
except:
  print("This application version is not supported")
  exit()


for row in df.itertuples():
  try:
    cursor.execute('''
    INSERT INTO customer ( CUST_ID                
     ,LAST_NAME              
     ,FIRST_NAME             
     ,EMAIL                  
     ,STREET_ADDRESS         
     ,POSTAL_CODE            
     ,CITY                   
     ,STATE_PROVINCE         
     ,COUNTRY_CODE           
     ,YRS_CUSTOMER           
     ,PROMOTION_RESPONSE     
     ,LOC_LAT                
     ,LOC_LONG               
     ,AGE                    
     ,COMMUTE_DISTANCE       
     ,CREDIT_BALANCE         
     ,EDUCATION              
     ,FULL_TIME              
     ,GENDER                 
     ,HOUSEHOLD_SIZE         
     ,INCOME                 
     ,INCOME_LEVEL           
     ,INSUFF_FUNDS_INCIDENTS 
     ,JOB_TYPE               
     ,LATE_MORT_RENT_PMTS    
     ,MARITAL_STATUS         
     ,MORTGAGE_AMT           
     ,NUM_CARS               
     ,NUM_MORTGAGES          
     ,PET                    
     ,RENT_OWN               
     ,SEGMENT_ID             
     ,WORK_EXPERIENCE        
     ,YRS_CURRENT_EMPLOYER   
     ,YRS_RESIDENCE          
     )
     VALUES ( :CUST_ID                
     ,:LAST_NAME              
     ,:FIRST_NAME             
     ,:EMAIL                  
     ,:STREET_ADDRESS         
     ,:POSTAL_CODE            
     ,:CITY                   
     ,:STATE_PROVINCE         
     ,:COUNTRY_CODE           
     ,:YRS_CUSTOMER           
     ,:PROMOTION_RESPONSE     
     ,:LOC_LAT                
     ,:LOC_LONG               
     ,:AGE                    
     ,:COMMUTE_DISTANCE       
     ,:CREDIT_BALANCE         
     ,:EDUCATION              
     ,:FULL_TIME              
     ,:GENDER                 
     ,:HOUSEHOLD_SIZE         
     ,:INCOME                 
     ,:INCOME_LEVEL           
     ,:INSUFF_FUNDS_INCIDENTS 
     ,:JOB_TYPE               
     ,:LATE_MORT_RENT_PMTS    
     ,:MARITAL_STATUS         
     ,:MORTGAGE_AMT           
     ,:NUM_CARS               
     ,:NUM_MORTGAGES          
     ,:PET                    
     ,:RENT_OWN               
     ,:SEGMENT_ID             
     ,:WORK_EXPERIENCE        
     ,:YRS_CURRENT_EMPLOYER   
     ,:YRS_RESIDENCE          
     )
     ''',
    [row.CUST_ID                
     ,row.LAST_NAME              
     ,row.FIRST_NAME             
     ,row.EMAIL                  
     ,row.STREET_ADDRESS         
     ,row.POSTAL_CODE            
     ,row.CITY                   
     ,row.STATE_PROVINCE         
     ,row.COUNTRY_CODE           
     ,row.YRS_CUSTOMER           
     ,row.PROMOTION_RESPONSE     
     ,row.LOC_LAT                
     ,row.LOC_LONG               
     ,row.AGE                    
     ,row.COMMUTE_DISTANCE       
     ,row.CREDIT_BALANCE         
     ,row.EDUCATION              
     ,row.FULL_TIME              
     ,row.GENDER                 
     ,row.HOUSEHOLD_SIZE         
     ,row.INCOME                 
     ,row.INCOME_LEVEL           
     ,row.INSUFF_FUNDS_INCIDENTS 
     ,row.JOB_TYPE               
     ,row.LATE_MORT_RENT_PMTS    
     ,row.MARITAL_STATUS         
     ,row.MORTGAGE_AMT           
     ,row.NUM_CARS               
     ,row.NUM_MORTGAGES          
     ,row.PET                    
     ,row.RENT_OWN               
     ,row.SEGMENT_ID             
     ,row.WORK_EXPERIENCE        
     ,row.YRS_CURRENT_EMPLOYER   
     ,row.YRS_RESIDENCE          ]
     )
    connection.commit()
  except cx_Oracle.IntegrityError:
    pass
  else:
    print("App version: %s - Edition: %s - Country Code %s - Inserting customer: %s %s" % (app_version, db_edition, row.COUNTRY_CODE, row.FIRST_NAME, row.LAST_NAME))
    time.sleep(2)


connection.close()

