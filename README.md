# Rummage

Rummage is a tiny, flexible, customizable gem that allows for quick searching and sorting through your ActiveRecord models. It does all this with a strong emphasis on being lightweight, unobtrusive, and familiar.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rummage'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rummage

## Rummage is: For Rails

Rummage gives your ActiveRecord models an extra bit of kick in terms of how you query them. It does so without introducing any massively new constructs into the existing query syntax.

So let's quickly look at something you can do with a Rummage powered model:
```ruby
User.search_in(:banned, :email).search(banned: true, email: { like: 'john.smith' })
```

Which quickly produces a SQL query that looks something like:
```sql
SELECT "users".* FROM "users" WHERE "users"."banned" = 't' AND ("users"."email" LIKE '%john.smith%')
```

Rummage comes with a lot of built-in functionality in terms of query-building. Here's a table that lists all of the built-ins and what they translate to in SQL. Note that Rummage handles escaping for you when doing `LIKE` queries.

| Rummage                         | SQL                           |
|---------------------------------|-------------------------------|
|`banned: true`                   | `"banned" = 't'`              |
|`role: ['foo', 'bar']`           | `"role" IN ('foo', 'bar')`    |
|`title: { not: nil }`            | `"title" IS NOT NULL`         |
|`age: { lt: 50, gteq: 15 }`      | `"age" < 50 AND "age" >= 15`  |
|`body: { like: 'susan' }`        | `"body" LIKE '%susan%'`       |
|`title: { starts_with: '100%' }` | `"title" LIKE '100\%%'`       |
|`email: { ends_with: '.com' }`   | `"email" LIKE '%.com'`        |

Rummage will also handle ordering for you! By default, Rummage looks for ordering definitions at the `_order` key, but this can be changed in configuration. So rummaging like this:
```ruby
User.search_in(:email, :post_count).search(_order: { post_count: :desc })
```

Translates into the query like this:
```sql
SELECT "users".* FROM "users" ORDER BY "users"."post_count" DESC
```

## Rummage is: For Controllers

Adding Rummage to your Rails controllers gives your app tons of search-power, without having to write any sort of complex logic yourself. All you need to do is let Rummage know which fields it's allowed to search in.

So, going forward with out little controller example:
```ruby
class UsersController < ApplicationController
  def index
    # Allow searching by user attributes, and by their posts.
    @users = User.search_in(:email, :post_count, posts: [:title, :body])
    @users = @users.search(params)
    
    render json: @users
  end
end
```

There. All you need to find quickly find users not only by their emails, but also by their posts. Rummage will even handle doing the `join(:posts)` for you, when necessary.

So now you can handle requests that would look something like:
```
api/users?post_title[starts_with]=ruby&_order[post_count]=desc
```
Note that the `posts.title` associated field translates to `post_title`. Associated fields are singularized by default, and separated by a single underscore. This can easily be changed in Rummage's configuration.

## Rummage is: Plug and Play

Adding Rummage into your existing models is about as easy as it gets.
```ruby
class User < ActiveRecord::Base
  include Rummage::Search
end
```

Rummage is implemented as a `Concern`, and introduces just 2 scopes into your models: `search_in` and `search`. If those names are already in use, or you'd just prefer them to be named something else, you can rename them in Rummage's configuration.

## Rummage is: Customizable

Rummage provides quite a bit of customizability, but only if it's necessary. Below is an example of a configuration file, with Rummage's defaults given as values.

```ruby
# Rename the scopes that Rummage adds.
Rummage::Config.search_in_name = :search_in
Rummage::Config.search_name    = :search

# Limit the number of filter and order conditions.
Rummage::Config.filter_order   = 10
Rummage::Config.order_limit    = 3

# Change the key used for ordering.
Rummage::Config.order_key      = '_order'
```

But there's more. Rummage allows you to define new ways to handle queries. Take the following as an example:
```ruby
Rummage::Builder.define do
  # Define a 'between' query builder, that works for integers, floats, and dates.
  query :between, types: %w(integer float datetime date time) do |field, value|
    if value.is_a?(Array) && value.length == 2
      model.arel_table[field].between(value[0], value[1])
    end
  end
end
```

Now we can take advantage of ouor new query builder:
```ruby
# Find users whose date-of-birth is between 50 and 15 years ago.
User.search_in(:date_of_birth).search(date_of_birth: { between: [50.years.ago, 15.years.ago] })
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Mihail-K/rummage.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

