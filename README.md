# Rummage

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rummage`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rummage'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rummage

## What is Rummage?

### Rummage is: For Rails
Rummage gives your ActiveRecord models some wicked new powers like searching and sorting with ease. 
For example, if you wanted to find every user whose email started with 'john', Rummage makes this trivial.
```ruby
User.search_in(:email).search(email: { starts_with: 'john' })
```

Which quickly produces a SQL query that looks like:
```sql
SELECT "users".* FROM "users" WHERE ("users"."email" LIKE 'john%')
```

Rummage does all the heavy lifting for you.

### Rummage is: Plug and Play
Include Rummage in your models
```ruby
class User < ActiveRecord::Base
  include Rummage::Search
end
```

Rummage requires no special configuration.

### Rummage is: Customizable
Rummage can be extended and made even more powerful by using your own query builders.

```ruby
Rummage::Builder.define do
  # Define a 'between' query builder, that works for integers, floats, and dates.
  query :between, types: %w(integer float date) do |field, value|
    if value.is_a?(Array) && value.length == 2
      model.arel_table[field].between(value[0], value[1])
    end
  end
end
```


```ruby
# Find users whose date-of-birth is between 50 and 15 years ago.
User.search_in(:date_of_birth).search(date_of_birth: { between: [50.years.ago, 15.years.ago] })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Mihail-K/rummage.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

