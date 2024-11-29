# SIS Import to Canvas from T-SQL Database

Connects to a T-SQL database and exports SQL as CSV files
Uses Instructure/Canvas' API to do a SIS Import of the CSV files

Get an API token from Canvas - assuming you're an Admin
Plug in the token, database details and update the SQL or create a view which matches the details. 
Run the script and you're away.

I've noticed sometimes the API will return a 400 for no reason but work the next day. Could be proxy related or could be Instructure. Not sure.
