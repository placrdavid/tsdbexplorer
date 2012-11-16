ALTER TABLE basic_schedules DISABLE TRIGGER ALL;
BEGIN;
update basic_schedules 
   set origin_tiploc = locations.tiploc_code, origin_name = tiplocs.tps_description
   from locations, tiplocs
   where basic_schedules.uuid = locations.basic_schedule_uuid
   and locations.tiploc_code = tiplocs.tiploc_code
   and locations.location_type = 'LO';
update basic_schedules 
   set destin_tiploc = locations.tiploc_code, destin_name = tiplocs.tps_description
   from locations, tiplocs
   where basic_schedules.uuid = locations.basic_schedule_uuid
   and locations.tiploc_code = tiplocs.tiploc_code
   and locations.location_type = 'LT';
COMMIT;
﻿ALTER TABLE basic_schedules ENABLE TRIGGER ALL;
