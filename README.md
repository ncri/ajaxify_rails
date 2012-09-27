# Ajaxify Rails

Rails gem for automatically turning internal links into ajax links that load content without a full page reload.

Uses the html5 history interface for changing the url and making the browser's back and forward buttons working with ajax.
Falls back to a hash based approach for browsers without the history interface (like Internet Explorer).
Transparently handles redirects and supports flash messages and page titles. Requires Ruby 1.9 and the asset pipeline.

Demo: http://ajaxify-demo.herokuapp.com/

Inspired by the pjax_rails gem (https://github.com/rails/pjax_rails)

## Installation

Add this line to your application's Gemfile:

    gem 'ajaxify_rails'

And then execute:

    $ bundle

In your application.js file add:

    //= require ajaxify_rails

## Usage



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
