select dbs.cluster_name, dbs.display_name as "dbsystem", dbs.domain, dbs.version , db.db_name, db.db_unique_name, db.pdb_name
from oci_database_db_system dbs
join oci_database_db db on dbs.id=db.db_system_id
where dbs.compartment_id='ocid1.compartment.oc1..aaaaaaaa7minmjq4rkcnleal3j2qhuuitkmhhqffz43tcnifjwm4a7qsdrua'

