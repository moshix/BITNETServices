#!/opt/homebrew/bin/python3.10
# planetary visibility by moshix copyright 2023, all rights reserved 
# v0.1 just make it work

import ephem
import datetime
import math


planets = [
    ephem.Moon(),
    ephem.Mercury(),
    ephem.Venus(),
    ephem.Mars(),
    ephem.Jupiter(),
    ephem.Saturn()
    ]


observer = ephem.Observer()
observer.name = "Houston"
observer.lon = '95.3698'
observer.lat = '29.7604'
observer.elevation = 86  # meters, though the docs don't actually say


observer.date = datetime.datetime.now()
sunset = observer.previous_setting(ephem.Sun())

min_alt = 10. * math.pi / 180.
print ("For observer point: ",observer.name)
for planet in planets:
    observer.date = sunset
    planet.compute(observer)
    if planet.alt > min_alt:
        print (planet.name, "is already up at sunset")

    midnight = list(observer.date.tuple())
    midnight[3:6] = [7, 0, 0]
    observer.date = ephem.date(tuple(midnight))
    planet.compute(observer)
    if planet.alt > min_alt:
        print (planet.name, "will rise before midnight")


