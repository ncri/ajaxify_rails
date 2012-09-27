# Ajaxify Rails

Rails gem for automatically turning internal links into ajax links that load content without a full page reload.

- Uses the html5 history interface for changing the url and making the browser's back and forward buttons work with ajax.
- Falls back to a hash based approach for browsers without the history interface (like Internet Explorer version <10)
- Hash and non-hash URLs are interchangeable.
- Transparently handles redirects and supports flash messages and page titles.
- Requires Ruby 1.9 and the asset pipeline.
- Tested with Chrome, Firefox, Safari and Internet Explorer 8+

Demo: http://ajaxify-demo.herokuapp.com/

Inspired by the pjax_rails gem (https://github.com/rails/pjax_rails)

## Installation

Add this line to your application's Gemfile:

    gem 'ajaxify_rails'

And then execute:

    $ bundle

In your application.js file add:

    //= require ajaxify_rails

## How it works

Ajaxify Rails automatically turns all absolute and relative internal site links into ajaxified links.
Clicking an ajaxified link sends an ajax request to rails. Ajaxify Rails makes sure that the request renders
without layout and inserts the response into the page's content area.

## Usage

### Content Area

Ajaxify Rails assumes that the content area html element has the id 'main'.
The content area html in your rails app is the container wrapping the yield statement in your layout.
If yield doesn't have a wrapper in your app, you need to supply one to get Ajaxify Rails working:

    #main
      = yield

You can change the content wrapper by setting

    Ajaxify.content_container = 'content_container_id'

### Page Title

If you define a method called 'page_title' in your application controller, Ajaxify Rails will use it to set
the page's title tag after successful ajaxify requests.

### Navigation and other layout updates

It's a common use case to have a navigation that needs to change its appearence and possibly functioning when the user navigates
to a different section of the page. Ajaxify Rails provides a success callback that is triggered after successful
ajaxify requests. Just hook into it and make your layout changes:

    Ajaxify.success ->
      # update navigation and/or other layout elements


### Flash Messages

Ajaxify Rails correctly displays your flash messages after ajaxified requests. To do so it stores flash messages in cookies.
By default, only flash[:notice] is supported. If you are using for example flash[:warning] as well you have to set:

    Ajaxify.flash_types = ['notice', 'warning']


### Root Redirects

Sometimes you need to redirect on the root url. For example you might have a localized application with the locale inside the url.
When a user navigates to your_domain.com he/she gets redirected to e.g. your_domain.com/en/. This works fine in browsers supporting
the html 5 history api. However, for browsers without the history api like Internet Explorer before version 10, Ajaxify needs hints
about your url structure to not get confused, creating endless redirects. So, if you need to support those browsers, you need to
explicitly supply some regex to Ajaxify. For example, if you need to support the root redirects to your_domain.com/en/ and your_domain.com/de/
you need to hint Ajaxyfiy like this:

    Ajaxify.base_path_regexp = /^(\/en|\/de)/i


### Extra Content

Sometimes you need to do non trivial modifications of the layout whenever the content in the main content area of your site changes.
Ajaxify Rails allows you to attach arbitrary html to ajaxified requests. This extra html is then stripped from the main content
that is inserted in the content area. But before that a callback is triggered which can be used to grab the extra content and do something with it.
To use this feature you need to provide a method ajaxify_extra_content in your ApplicationController:

    def ajaxify_extra_content
      ... your extra html ...
    end

For example you could provide url for a widget in the layout like this:

    def ajaxify_extra_content
      "<div id='may_fancy_widget_html'> some html </div>"
    end

And then, on the client side hook into Ajaxify via the handle_extra_content callback and select the widget html via #ajaxify_content:

    Ajaxify.handle_extra_content = ->
      $('#my_fancy_widget').html $('#ajaxify_content #my_fancy_widget').html()


### Reference: All Options and Callbacks

Here is a reference of all options and callbacks you can set via Ajaxify.option_or_callback:

    option/callback          default       description

    active                   true          Toggles ajaxifying of links.
    content_container       'main'         Id of the container to insert the main content into ("yield wrapper").
    base_path_regexp         null          Regex hint for applications with root url redirects.

    on_before_load           null          Callback: Called before the ajaxify request is started.
    on_success               null          Callback: Called when an ajaxify requests finished successfully.
    on_success_once          null          Callback: Like on_success but only called once.
    handle_extra_content     null          Callback: Called before extra content is stripped from the ajax request's response.

    flash_types              ['notice']    Flash types your Rails app uses. E.g. ['notice', 'warning', 'error']
    flash_effect             null          Callback: Called for each flash type after flash is set.
    clear_flash_effect       null          Callback: Called for each flash type whenever flash message is not present

Also check the example app source code for usage: https://github.com/ncri/ajaxify_rails_demo_app


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
