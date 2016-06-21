REPORT Z_OTHER_DATA_TYPES.

TABLES: ZEMPLOYEES2.

* Date and Time Fields
********************
* Date fields format: YYYYMMDD with initial value of '00000000'.
DATA MY_DATE TYPE D VALUE '20120101'.
DATA MY_DATE2 LIKE SY-DATUM.

* Time fields format: HHMMSS with initial value of '000000'.
DATA MY_TIME TYPE T VALUE '111005'.
DATA MY_TIME2 LIKE SY-UZEIT.

*********************
*Field for Date Calculations

DATA EMPL_SDATE   TYPE D.
DATA TODAYS_DATE  TYPE D.
DATA LOS          TYPE I.
DATA DAYS_COUNT   TYPE I.
DATA FUT_DATE     TYPE D.

*********************
*Field for Time Calculations

DATA CLOCK_IN       TYPE T.
DATA CLOCK_OUT      TYPE T.
DATA SECONDS_DIFF   TYPE I.
DATA MINUTES_DIFF   TYPE I.
DATA HOURS_DIFF     TYPE P DECIMALS 2.

*********************
*Currency & Quantity Fields
* Field for Currency Calculations

DATA MY_SALARY      LIKE ZEMPLOYEES2-SALARY.
DATA MY_TAX_AMOUNT  LIKE ZEMPLOYEES2-SALARY.
DATA MY_NET_PAY     LIKE ZEMPLOYEES2-SALARY.
DATA TAX_PERC       TYPE P DECIMALS 2.

*********************
* Test Date & Time Fields Output

WRITE:  MY_DATE,
      / MY_DATE2,
      / MY_TIME,
      / MY_TIME2.
ULINE.
*********************

EMPL_SDATE = '20090515'.
TODAYS_DATE = SY-DATUM.
LOS = TODAYS_DATE - EMPL_SDATE.

WRITE / LOS.
ULINE.
*********************

TODAYS_DATE = SY-DATUM.
DAYS_COUNT = 20.
FUT_DATE = TODAYS_DATE + DAYS_COUNT.

WRITE / FUT_DATE.
ULINE.
*********************

TODAYS_DATE = SY-DATUM.
TODAYS_DATE+6(2) = '20'.
FUT_DATE = TODAYS_DATE + DAYS_COUNT.

WRITE / FUT_DATE.
WRITE / SY-DATUM.
ULINE.
*********************

TODAYS_DATE = SY-DATUM.
TODAYS_DATE+6(2) = '01'.
TODAYS_DATE = TODAYS_DATE - '01'.
FUT_DATE = TODAYS_DATE + DAYS_COUNT.

WRITE / TODAYS_DATE.
ULINE.
*********************
*Time Calculations

CLOCK_IN = '073000'.
CLOCK_OUT = '160000'.
SECONDS_DIFF = CLOCK_OUT - CLOCK_IN.

ULINE.

WRITE: / 'clock in: ', CLOCK_IN, '   clock out: ', CLOCK_OUT.
WRITE: / 'difference in seconds: ', SECONDS_DIFF.

MINUTES_DIFF = SECONDS_DIFF / 60.
WRITE: /  'difference in minutes: ', MINUTES_DIFF.

HOURS_DIFF = MINUTES_DIFF / 60.
WRITE: /  'difference in hours: ', HOURS_DIFF.

ULINE.
**********************
*Currency Calculations

TAX_PERC = '0.20'.

SELECT * FROM ZEMPLOYEES2.
  WRITE:  / ZEMPLOYEES2-SURNAME, ZEMPLOYEES2-SALARY, ZEMPLOYEES2-ECURRENCY.

  MY_TAX_AMOUNT = TAX_PERC * ZEMPLOYEES2-SALARY.
  MY_NET_PAY = ZEMPLOYEES2-SALARY - MY_TAX_AMOUNT.
  WRITE: / 'tax amount: ', MY_TAX_AMOUNT, ZEMPLOYEES2-ECURRENCY,
           'net amount: ', MY_NET_PAY, ZEMPLOYEES2-ECURRENCY.
  SKIP.
ENDSELECT.
ULINE.