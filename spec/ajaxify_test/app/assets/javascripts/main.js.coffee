
#Ajaxify.init
#  flash_types: ['notice', 'warning']
#  base_paths: ['de']

jQuery ->
  $(document).on 'ajaxify:content_loaded', (event, data, status, jqXHR, url) ->
    $nav_links = $('#navigation a')
    $nav_links.removeClass 'active'
    $nav_links.filter( ->
      href = $(this).attr('href')
      (window.location.pathname == href and window.location.hash == '') or   # for browsers with histori api
      window.location.hash.match(new RegExp("^#(#{href}\\?|#{href}$)"))      # for browsers without histori api
    ).addClass 'active'

  flash_timeout = null

  $(document).on 'ajaxify:flash_displayed', (event, flash_type) ->
    clearTimeout flash_timeout if flash_timeout
    flash_timeout = setTimeout( ->
      $("##{flash_type}").fadeOut()
    , 5000)

#  $('body').on 'ajaxify:before_load', (event, url) ->
#    alert "Will load #{url}"
#
#  $('body').on 'ajaxify:content_loaded', (event, data, status, jqXHR, url) ->
#    alert "Content loaded"
#
#  $('body').on 'ajaxify:content_inserted', ->
#    alert "Content inserted"


