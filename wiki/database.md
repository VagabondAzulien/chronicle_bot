# @markup markdown
# @title Database

# Chronicle Database

Chronicle leverages a database for persistent storage. It uses ActiveRecord for
interfacing with the supported database types, performing migrations, and
interacting with models.

## Supported Databases

### Currently Supported:

- SQLite

### Planned Support:

- PostgreSQL
- MySQL
- MariaDB

## Creating the Database

There's a Rake task for creating the database according to ActiveRecord: `rake
db:create`. For configuration, check out `config/db.yml`. The default
configuration will create a SQLite3 database at `db/chronicle-bot.db`.

## Working With the Migrations

ActiveRecord migrations are database-agnostic schema alterations, stored as
code. This allows Chronicle to support multiple different database
architectures, without having to write custom code for each one.  Migrations can
represent changes tied to new versions, or additional database configuration
tied to an add-on or protocol, for example.

To apply the migrations, use the Rake task `rake db:migrate`.

To roll-back the migrations, use the Rake task `rake db:down`.

### Provided Migrations

By default, Chronicle includes a migration for setting up the "general" table,
which provides details around the bot itself.

It also includes a migration for the Custom Commands add-on, which creates a
table for storing the commands and responses, along with the room ID the command
was created in.

Each of these migrations include a "roll-back" solution, which simply drops the
corresponding tables.

### Writing Additional Migrations

The most important thing when creating new migrations is to follow the naming
convention: 

```
   XXXX_name_of_migration.rb
```

The Rake tasks for working with migrations will look at every file in the
`db/migrate/` directory, and sort them. It will `require` those files, and then
compile a list of the classes within those files according to specific logic: it
takes the file name, drops the numbers at the beginning, and converts the file
name from snake case and to camel case, dropping the file extension. For example,
"0000_create_general.rb" will be processed to the class named "CreateGeneral",
which will be added to a list. The Rake task will then go through each the list
of all classes and run the "migrate" method of each class, passing it "up" if
migrations are being applied, or "down" if migrations are being rolled-back.

Generally speaking, the number for the migration is mostly important for sorting
order. However, a simple naming convention can help distinguish between types of
migrations, by changing the 2nd-position digit:

- For migrations tied to Chronicle functionality, use `00XX`.
- For migrations tied to addon functionality, use `01XX`.
- For migrations tied to protocol functionality, use `02XX`.
- For any miscellaneous migrations, use `03XX`.
