active = true
content_container = 'main'
base_paths = null
flash_types = ['notice']
dont_correct_url = false
push_state_enabled = true

ignore_hash_change = null
load_page_from_hash = null

scroll_to_top = true

initial_history_state =
  url: window.location.href
  data:
    ajaxified: true

base_path_regexp_cache = null


# --------------------------------------------------------------------------------------------------------------------
# public methods
# --------------------------------------------------------------------------------------------------------------------

activate = (new_active = true) ->
  active = new_active

get_content_container = ->
  content_container

set_content_container = (new_content_container) ->
  content_container = new_content_container

init = (options = {}) ->
  base_paths = options.base_paths if 'base_paths' of options
  flash_types = options.flash_types if 'flash_types' of options
  push_state_enabled = options.push_state_enabled if 'push_state_enabled' of options
  active = options.active if 'active' of options
  content_container = options.content_container if 'content_container' of options
  correct_url() unless $('meta[name="ajaxify:dont_correct_url"]').length > 0
  scroll_to_top = options.scroll_to_top if 'scroll_to_top' of options


ajaxify = ->
  if active

    if load_page_from_hash
      load_page_from_hash = false
      on_hash_change()

    protocol_and_hostname = "#{window.location.protocol}//#{window.location.hostname}"

    $('body').on 'click', "a[href^='/']:not(.no_ajaxify), a[href^='#{protocol_and_hostname}']:not(.no_ajaxify)", ->
      $this = $(this)

      load
        url: $this.attr('href')
        type: $this.data('method')
        confirm: $this.data('confirm')
        scroll_to_top: set_scroll_to_top($this)

      false

    exclude_selector = ":not(.no_ajaxify):not([enctype='multipart/form-data'])"
    $('body').on 'submit', "form[action^='/']#{exclude_selector},
                            form[action^='#{protocol_and_hostname}']#{exclude_selector},
                            form[action='']#{exclude_selector}", ->

      $this = $(this)

      form_params = $(this).serialize()
      form_params += '&ajaxified=true'

      action = $this.attr('action')

      load
        url: if action != '' then action else '/'
        data: form_params
        type: $this.attr('method')
        confirm: $this.data('confirm')
        scroll_to_top: set_scroll_to_top($this)

      false

  # (history interface browsers only)
  $(window).on 'popstate', (e) ->
    e = e.originalEvent
    if e.state and e.state.data and e.state.data.ajaxified
      e.state.cache = false
      load e.state, true

  # (non history interface browsers only)
  window.onhashchange = ->
    unless ignore_hash_change
      on_hash_change()
    else
      ignore_hash_change = false


load = (options, pop_state = false) ->

  unless load_page_from_hash

    data = options.data || { ajaxified: true }

    if options.type and options.type == 'delete'
      type = 'post'
      if is_string(data)
        data += '&_method=delete'
      else
        data._method = 'delete'
    else
      type = options.type or 'get'

    if options.confirm
      return false unless confirm options.confirm

    $(document).trigger 'ajaxify:before_load', [options, pop_state]

    $.ajax
      url: options.url
      dataType: 'html'
      data:  data
      type: type
      cache: true
      beforeSend: (xhr) ->
        $("##{content_container}").html( "<div class='ajaxify_loader'></div>" )
        options.scroll_to_top = scroll_to_top unless 'scroll_to_top' of options
        scroll_page_to_top() if options.scroll_to_top

      success: (data, status, jqXHR) ->
        on_ajaxify_success data, status, jqXHR, pop_state, options


# --------------------------------------------------------------------------------------------------------------------
# private methods
# --------------------------------------------------------------------------------------------------------------------

update_url = (options, pop_state = false) ->

  get_request = (!options.type or options.type.toLowerCase() == 'get')

  # unless back/forward arrowing or request method is not 'get'
  if !pop_state and get_request

    if push_state()

      if initial_history_state != ''
        window.history.replaceState initial_history_state, ''
        initial_history_state = ''

      options.data ||= {}
      options.data.ajaxified = true
      window.history.pushState
        url: options.url
        data: options.data
        type: options.type
      ,'', options.url

    else
      ignore_hash_change = true  # for non histroy interface browsers: avoids loading the page for hash changes caused by link clicks
      hash = "#{options.url.replace(new RegExp(protocol_with_host()), '')}"

      if base_path_regexp()
        hash = hash.replace(base_path_regexp(), '')
        hash = "/#{hash}" unless hash == '' or hash.indexOf('/') == 0

      window.location.hash = hash


on_ajaxify_success = (data, status, jqXHR, pop_state, options) ->

  response = $("<div></div>").append(data)
  ajaxify_content = response.find('#ajaxify_content')

  title = ajaxify_content.data('page-title')
  flashes = ajaxify_content.data('flashes')
  container = ajaxify_content.data('container') || content_container

  $("##{container}").html response.html()

  # Correct the url after a redirect and when it has the ajaxify param in it.
  # The latter can happen e.g. for pagination links that are auto generated.
  original_request_type = options.type
  current_url = $('#ajaxify_content #ajaxify_location').html()
  if options.url != current_url
    options.url = current_url.replace(/(&|&amp;|\?)ajaxify_redirect=true/,'')
    options.type = 'GET'

  unless original_request_type and original_request_type.toLowerCase() == 'post'
    reload_page_if_assets_stale options.url, jqXHR

  update_url options, pop_state

  $(document).trigger 'ajaxify:content_inserted'

  $("##{container} #ajaxify_content").remove()

  if title
    document.title = title.replace /&amp;/, '&'   # Todo: need to figure out what else needs to be unescaped

  show_flashes(flashes)

  $(document).trigger('ajaxify:content_loaded', [data, status, jqXHR, options.url])


correct_url = ->
  if active
    if window.location.hash.indexOf('#') == 0   # if url has a '#' in it treat it as a non history interface hash based scheme url
      return unless window.location.hash.match(/^#(\/|\?)/) # check hash format

      if !push_state()
        load_page_from_hash = true   # notify Ajaxify that a hash will be loaded and ignore all other calls to load until hash url is loaded
      else
        # load proper url in case browser supports history api
        path = window.location.pathname
        path = '' if path == '/'
        path = path + window.location.hash.replace(/#/, "")
        window.location.href = "#{protocol_with_host()}#{path}"

    else if !push_state() # move path behind '#' for browsers without history api
      if base_path_regexp() and (match = window.location.pathname.match(base_path_regexp()))
        if match[0] == window.location.pathname
          if window.location.search == ''
            return   # we are on a base path here already, so don't do anything
          else
            path = match[0].replace(/\?/,'') + '#'
        else
          path = "#{match[0].replace(/\/$/,'')}#/#{window.location.pathname.replace(match[0],'')}"
      else if window.location.pathname == '/'
        if window.location.search != ''
          window.location.href = "#{protocol_with_host()}/#/#{window.location.search}" # move search behind #
        return
      else
        path = "/##{window.location.pathname}"

      window.location.href = "#{protocol_with_host()}#{path}#{window.location.search}"


show_flashes = (flashes) ->
  $.each flash_types, ->
    if flashes and flashes[this]
      $("##{this}").html flashes[this]
      $("##{this}").show()
      $(document).trigger 'ajaxify:flash_displayed', [this]

    else
      $("##{this}").hide()


# load content from url hash (non history interface browsers)
on_hash_change = ->
  url = window.location.hash.replace(/#/, "")

  if match = window.location.pathname.match(base_path_regexp())
    url = match[0] + url

  url = '/' if url == ''
  hash_changed = true

  load
    url: url
  , true


base_path_regexp = ->
  return null unless base_paths
  return base_path_regexp_cache if base_path_regexp_cache
  # match starting and ending with base path, e.g. "^\/en$" (i.e. we are at the base path root) or
  # starting with base path and continuing with '/', e.g. "^\/en\/" (i.e. we are NOT at the base path root) or
  # starting with base path and continuing with '?', e.g. "^\/en\?" (i.e. we are at the base path root and have query params)
  base_path_regexp_cache = new RegExp("^\/(#{ $.map(base_paths, (el) ->
    el = regexp_escape el
    "#{el}($|\/|\\?)"
  ).join('|')})", 'i')


is_string = (variable) ->
  Object.prototype.toString.call(variable) == '[object String]'


regexp_escape = (str) ->
  str.replace new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\-]', 'g'), '\\$&'


protocol_with_host = ->
  loc = window.location
  "#{loc.protocol}//#{loc.host}"


push_state = ->
  push_state_enabled and window.history.pushState


set_scroll_to_top = ($link_or_form) ->
  scroll = $link_or_form.hasClass('scroll_to_top')
  no_scroll = $link_or_form.hasClass('no_scroll_to_top')
  if scroll or no_scroll then return (scroll and !no_scroll) else return scroll_to_top


scroll_page_to_top = ->
  $('html, body').animate
    scrollTop:0
    , 500


reload_page_if_assets_stale = (url, jqXHR) ->
  digest_header = jqXHR.getResponseHeader('Ajaxify-Assets-Digest')
  if digest_header and digest_header != $("meta[name='ajaxify:assets-digest']").attr('content')
    document.location.href = url

# --------------------------------------------------------------------------------------------------------------------
# public interface
# --------------------------------------------------------------------------------------------------------------------

@Ajaxify = { init, ajaxify, load, update_url, activate, set_content_container, get_content_container }


# --------------------------------------------------------------------------------------------------------------------
# ajaxify page on dom ready
# --------------------------------------------------------------------------------------------------------------------

jQuery ->
  Ajaxify.ajaxify()
