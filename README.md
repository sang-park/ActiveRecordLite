# ActiveRecordLite

This is a lightweight ORM inspired by ActiveRecord.

## Overview

ActiveRecordLite supports basic database query methods such as where, find, update, save, and insert. It is also able to create 'has_many', 'belongs_to', 'has_one_through' associations using Ruby metaprogramming.

### Getting Started
To use ActiveRecordLite, download the repository and require 'active_record_lite.rb' file from the lib file into your rails model. Inherit 'ActiveRecordLite' in your model class, and you should have access to all of ActiveRecordLite's methods.

### Creating a Database Connection

ActiveRecordLite uses SQLite3 to create a connection with the database. Typically, each row is returned as an array of values, and all values are returned as unparsed strings. Setting 'results_as_hash' and 'type_translation' to true ensures that the each row is returned as an hash with the column name as key, and the values are parsed into the appropriate type. 
```
def self.open(db_file_name)
  @db = SQLite3::Database.new(db_file_name)
  @db.results_as_hash = true
  @db.type_translation = true

  @db
end
```
### SQL Escapes

Few defenses were set up in order to protect the database against SQL injections. One way that ActiveRecordLite sanitizes its user input is using the question mark interpolation, as such:
```
  found = DBConnection.execute(<<-SQL, id)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      id = ?
  SQL
```
Using this syntax, where the inputs are passed in as arguments, and picked up using the question mark interpolation, ensures that the inputs are sanitized when the query is sent to the database.
