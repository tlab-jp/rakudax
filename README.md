# Rakudax

[![Build Status](https://travis-ci.org/tlab-jp/rakudax.svg?branch=master)](https://travis-ci.org/tlab-jp/rakudax)  
[![Code Climate](https://codeclimate.com/github/tlab-jp/rakudax/badges/gpa.svg)](https://codeclimate.com/github/tlab-jp/rakudax)  
[![Test Coverage](https://codeclimate.com/github/tlab-jp/rakudax/badges/coverage.svg)](https://codeclimate.com/github/tlab-jp/rakudax/coverage)  

Data migration tool using (ruby)Active Record.   
For more information about [tlab-jp/rakuda](https://github.com/tlab-jp/rakuda).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rakudax'

## If using sqlite database, then comment-in this line.
#gem 'sqlite3'

## If using mysql database, then comment-in this line.
#gem 'mysql2'

## If using postgresql database, then comment-in this line.
#gem 'pg'

## If using ms sqlserver datavase, then comment-in this line.
#gem 'tiny_tds'
#gem 'activerecord-sqlserver-adapter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rakudax

## Usage

```
===========================================================================
<>: required
[]: optional

## new rakuda project creation
Usage: rakudax new [name]

 name: project name

## rakuda project execution
Usage: rakudax <control> [Options]

 control: generate, submit, migrate, verify

 Options:
 
 --setting <path>        *path to control setting file (default: config/<control>.yml)
 --database <path>       *path to database setting file (default: config/database.yml)
 --modules <path>        path to modules directory
 --env <enviroment>      control-setting enviroment (default: development)
 --intermediate <path>   path to intermediate files (default: dist/intermediate_files)
 --verify <path>         path to verify files (default: dist/verify)
 --threads <num>         threads num in generate (deafult: 1)
 --yaml                  change output type to yaml (default: json)

 *only support yaml setting file
===========================================================================
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tlab/rakudax. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

