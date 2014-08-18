# Mandrake

[![Build Status](https://travis-ci.org/namusyaka/mandrake.svg)](https://travis-ci.org/namusyaka/mandrake)
[![Gem Version](https://badge.fury.io/rb/mandrake.svg)](http://badge.fury.io/rb/mandrake)
[![Code Climate](https://codeclimate.com/github/namusyaka/mandrake/badges/gpa.svg)](https://codeclimate.com/github/namusyaka/mandrake)

Mandrake loads middlewares conditionally, and it provides two options and DSL for setting conditions.
If you use Mandrake, you can avoid executing unnecessary middlewares by setting conditions.

## Installation

Add this line to your application's Gemfile:

    gem 'mandrake'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mandrake

## Builder

Mandrake provides `:if` and `:unless` options which are available on `#use` method.
These options can be used to set the condition to enable the middleware at runtime.

```ruby
Mandrake::Builder.new do
  use Rack::Deflate, if:     request.path_info.start_with?("/deflater")
  use Rack::ETag,    unless: request.path_info.end_with?("etag")
  run ->(env){ [200, {'Content-Type' => 'text/plain'}, ["Hello World"]] }
end
```

Mandrake provides `env` and `request` methods for building the conditional expression.
They can be used in the block.

```ruby
Mandrake::Builder.new do
  request.path_info.start_with?("/public") #=> 'request.path_info.start_with?("/public")'
  env["PATH_INFO"] == "/public" #=> 'env["PATH_INFO"] == "/public"'
end
```

If you want to use these without the block executed on initialization,
you must pass the **proc** to the conditional options.

```ruby
builder = Mandrake::Builder.new
builder.use Rack::Deflater, if: proc{ request.path_info.start_with?("/public") }
```

The arguments of these options allow to pass the **lambda**, but its behavior is different from **proc**.
**lambda** is defined as the validation method by `define_method`. Therefore the validation method will be slow.

```ruby
Mandrake::Builder.new do
  use Rack::Deflate, if: proc{ request.path_info.start_with?("/deflater") }
  run ->(env){ [200, {'Content-Type' => 'text/plain'}, ["Hello World"]] }
end
```

In the end, `Mandrake::Builder` inherits `Rack::Builder`, so you can use this like `Rack::Builder` basically.
Of course, it does not break the compatibility.

## Middleware

This class is for incorporating mandrake into your application easily.
You can use as well as the Rack Middleware.

```ruby
use Mandrake::Middleware do
  use Rack::Deflate, if:     request.path_info.start_with?("/deflater")
  use Rack::ETag,    unless: request.path_info.end_with?("etag")
end
```

## Contributing

1. Fork it ( https://github.com/namusyaka/mandrake/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
