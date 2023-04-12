#!/opt/homebrew/bin/python3.10
# Planet ascension calculation (not optimized)
# copyright 2023 by moshix, all rights reserverd
# You may not copy or reproduct to program

import ephem
import datetime
import time
import math


# Set observer location
observer = ephem.Observer()
#observer.lon = '-122.03'  # longitude of observer in degrees
#observer.lat = '37.37'   # latitude of observer in degrees
#observer.elevation = 10  # elevation of observer in meters

observer.name = "Houston"
observer.lon = '95.3698'
observer.lat = '29.7604'
observer.elevation = 86
print ("Please input closeness tolerance in percengage [2.4 = 0.024]: ")
tol =input()
tolerance=float(tol)

# Set date and time
date = datetime.date(2023, 4, 12)  # format: yyyy/mm/dd hh:mm:ss
observer.date = date
enddate = datetime.date(4225, 4, 18)
delta = datetime.timedelta(days=1)

print("Mercury", "\t\t", " Venus", "\t\t"," Mars", "\t\t\t"," Jupiter", "\t\t\t", " Saturn", "\t\t\t", " Uranus", "\t\t", " Neptune")
while (date  <= enddate):
   date += delta
   observer.date = date

   # Create planet objects
   mercury = ephem.Mercury()
   venus = ephem.Venus()
   mars = ephem.Mars()
   jupiter = ephem.Jupiter()
   saturn = ephem.Saturn()
   uranus = ephem.Uranus()
   neptune = ephem.Neptune()
   
   # Compute positions of planets
   mercury.compute(observer)
   venus.compute(observer)
   mars.compute(observer)
   jupiter.compute(observer)
   saturn.compute(observer)
   uranus.compute(observer)
   neptune.compute(observer)
  
#   print('Mercury       Venus     Mars    Jupiter    Saturn   Uranus  Neptune')
   # Print positions of planets
#  print(mercury.ra, mercury.dec, "\t", venus.ra, venus.dec, "\t", mars.ra, mars.dec, "\t", jupiter.ra, jupiter.dec, "\t", saturn.ra, saturn.dec, "\t", uranus.ra, uranus.dec, "\t", neptune.ra, neptune.dec)
# relative tolerance 2.4%

   if math.isclose(mercury.ra, venus.ra, rel_tol = tolerance) and math.isclose(venus.ra, mars.ra, rel_tol = tolerance) and math.isclose(mars.ra, jupiter.ra, rel_tol = tolerance) and math.isclose(jupiter.ra, saturn.ra, rel_tol = tolerance) and math.isclose(saturn.ra, uranus.ra, rel_tol = tolerance) and math.isclose(uranus.ra, neptune.ra, rel_tol = tolerance):
       print("**************Alignment on Right Ascension found for: ", str(observer.date))

   if math.isclose(mercury.dec, venus.dec, rel_tol = tolerance) and math.isclose(venus.dec, mars.dec, rel_tol = tolerance) and math.isclose(mars.dec, jupiter.dec, rel_tol = tolerance) and math.isclose(jupiter.dec, saturn.dec, rel_tol = tolerance) and math.isclose(saturn.dec, uranus.dec, rel_tol = tolerance) and math.isclose(uranus.dec, neptune.dec, rel_tol = tolerance):
       print("**************Alignment on Declination found for: ", str(observer.date))

#   print('Venus:', venus.ra, venus.dec)
#   print('Mars:', mars.ra, mars.dec)
#   print('Jupiter:', jupiter.ra, jupiter.dec)
#   print('Saturn:', saturn.ra, saturn.dec)
#   print('Uranus:', uranus.ra, uranus.dec)
#   print('Neptune:', neptune.ra, neptune.dec)
print(mercury.ra, mercury.dec, "\t", venus.ra, venus.dec, "\t", mars.ra, mars.dec, "\t", jupiter.ra, jupiter.dec, "\t", saturn.ra, saturn.dec, "\t", uranus.ra, uranus.dec, "\t", neptune.ra, neptune.dec)
