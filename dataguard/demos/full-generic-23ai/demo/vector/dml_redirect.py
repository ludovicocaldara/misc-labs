import os
import array
import random
import oracledb

oracledb.init_oracle_client()

user = os.getenv("DB_USER", "tacuser")
dsn  = os.getenv("DB_DSN", "mypdb_ro.adghol23.misclabs.oraclevcn.com")
pw   = os.getenv("DB_PASS", "WElcome123##")

con = oracledb.connect(user=user, password=pw, dsn=dsn)
cur = con.cursor()

dims = 30000

# Generate float32 values between -1 and 1
vec_vals = [random.uniform(-1, 1) for _ in range(dims)]
vec32 = array.array("f", vec_vals)  # 32-bit floats


cur.execute("ALTER SESSION ENABLE ADG_REDIRECT_DML")

cur.execute(
    "INSERT INTO V (V) VALUES (:1)",
    [vec32]
)
con.commit()

print(f"Inserted ", dims, "-dimensional vector in float32 format.")
con.close()

