import sys

from lunisolar import ChineseDate

year = int(sys.argv[1])
month = int(sys.argv[2])
day = int(sys.argv[3])

gregorian_date = ChineseDate.from_chinese(chinese_year=year, chinese_month=month, chinese_day=day, is_leap_month=False).gregorian_date
print("(:YEAR {} :MONTH {} :DAY {})".format(gregorian_date.year, gregorian_date.month, gregorian_date.day))
