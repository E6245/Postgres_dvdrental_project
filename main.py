# main.py

import smtplib
import psycopg2
import select

my_email = "INSERT EMAIL HERE"
password = "INSERT GMAIL APP PASSWORD HERE NO SPACES"
SUB = "New movie alert!"

def sendmail(name, email, msg):
	with smtplib.SMTP("smtp.gmail.com", port=587)as connection:
		connection.starttls()
		connection.login(user=my_email, password=password)
		connection.sendmail(from_addr=my_email, to_addrs=email, 
msg=f"Subject:{SUB}\n\nDear {name},\n\n{msg}\n\n\n-Your Friends at EHQ Video")

def dblisten(conn):
	try:
		cursor = conn.cursor()
		cursor.execute("SELECT customer_name, email FROM rpc_test WHERE top_customer = true;")
		rows = cursor.fetchall()
		cursor.execute("LISTEN newmovies;")
		print("Listening on channel newmovies")
		while True:
			select.select([conn], [], [], 1)
			conn.poll()
			while conn.notifies:
				notify = conn.notifies.pop().payload
				print("Received notice:", notify)
				for row in rows:
					sendmail(row[0], row[1], notify)
	except KeyboardInterrupt:
		print("\nExiting...")
	finally:
		cursor.close()

if __name__ == '__main__':

	conn = psycopg2.connect(host="localhost", database="dvdrental", user="USERNAME FOR POSTGRES", password="POSTGRES PASSWORD")
	conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
		
	dblisten(conn)




