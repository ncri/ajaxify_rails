@Ajaxify =

  # options
  #
  active: true
  content_container: 'main'
  handle_extra_content: null
  base_paths: null

  # callbacks
  #
  on_before_load: null
  on_success: null
  on_success_once: null
  on_before_correct_url: null

  # flash
  #
  flash_types: ['notice']
  flash_effect: null
  clear_flash_effect: null

  # internal use only
  #
  hash_changed: null
  ignore_hash_change: null
  load_page_from_hash: null

  initial_history_state:
    url: window.location.href
    data:
      ajaxified: true


  ajaxify: ->

    if this.active

      if this.load_page_from_hash
        this.load_page_from_hash = false
        this.on_hash_change()

      self = this

      protocol_and_hostname = "#{window.location.protocol}//#{window.location.hostname}"

      $('body').on 'click', "a[href^='/']:not(.no_ajaxify), a[href^='#{protocol_and_hostname}']:not(.no_ajaxify)", ->

        $this = $(this)
        self.load
          url: $this.attr('href')
          type: $this.data('method')
          confirm: $this.data('confirm')

        false

      exclude_selector = ":not(.no_ajaxify):not([enctype='multipart/form-data'])"
      $('body').on 'submit', "form[action^='/']#{exclude_selector},
                              form[action^='#{protocol_and_hostname}']#{exclude_selector},
                              form[action='']#{exclude_selector}", ->

        $this = $(this)
        form_params = $(this).serialize()
        form_params += '&ajaxified=true'

        action = $this.attr('action')

        self.load
          url: if action != '' then action else '/'
          data: form_params
          type: $this.attr('method')
          confirm: $this.data('confirm')

        false


    window.onpopstate = (e) ->
      if e.state
        e.state.cache = false
        self.load e.state, true


    window.onhashchange = ->
      if window.location.hash.indexOf('#/') == 0  # only react to hash changes if hash starts with '/'
        unless self.ignore_hash_change
          self.on_hash_change()
        else
          self.ignore_hash_change = false


  on_hash_change: ->
    url = window.location.hash.replace(/#/, "")
    if url == ''
      url = '/'
    this.hash_changed = true
    this.load
      url: url


  load: (options, pop_state = false) ->

    unless this.load_page_from_hash
      self = this

      data = options.data || { ajaxified: true }

      if options.type and options.type == 'delete'
        type = 'post'
        if self.is_string(data)
          data += '&_method=delete'
        else
          data._method = 'delete'
      else
        type = options.type or 'get'

      if options.confirm
        return false unless confirm options.confirm

      if self.on_before_load
        self.on_before_load options.url

      $.ajax
        url: options.url
        dataType: 'html'
        data:  data
        type: type
        cache: true
        beforeSend: (xhr) ->
          $("##{self.content_container}").html( "<div class='ajaxify_loader'></div>" )
          $('html, body').animate
            scrollTop:0
            , 500

        success: (data, status, jqXHR) ->
          self.on_ajaxify_success data, status, jqXHR, pop_state, options


  show_flash: () ->
    self = this
    $.each this.flash_types, ->
      cookie_name = "flash_#{this}"
      if $.cookie cookie_name
        $("##{this}").html $.cookie(cookie_name)
        $.cookie cookie_name, null
        $("##{this}").show()
        if self.flash_effect
          self.flash_effect this
      else
        if self.clear_flash_effect
          self.clear_flash_effect this
        $("##{this}").hide()


  on_ajaxify_success: (data, status, jqXHR, pop_state, options) ->

    $("##{this.content_container}").html data

    title = $('#ajaxify_content').data('page-title')

    # Correct the url after a redirect and when it has the ajaxify param in it.
    # The latter can happen e.g. for pagination links that are auto generated.
    current_url = $('#ajaxify_content #ajaxify_location').text()
    if options.url != current_url
      options.url = current_url.replace(/(&|\?)ajaxify_redirect=true/,'')
      options.type = 'GET'

    if not this.hash_changed  # no need to update url if the ajax call resulted in a hash change
      this.update_url options, pop_state
    else
      this.hash_changed = false


    if this.handle_extra_content
      this.handle_extra_content()

    $("##{this.content_container} #ajaxify_content").remove()

    if title
      document.title = title.replace /&amp;/, '&'   # Todo: need to figure out what else needs to be unescaped

    this.show_flash()

    if this.on_success
      this.on_success( data, status, jqXHR, options.url )

    if this.on_success_once
      this.on_success_once( data, status, jqXHR )
      this.on_success_once = null


  update_url: (options, pop_state = false) ->

    get_request = (!options.type or options.type.toLowerCase() == 'get')

    # unless back/forward arrowing or request method is not 'get'
    if !pop_state and get_request

      if window.history.pushState

        if this.initial_history_state != ''
          window.history.replaceState this.initial_history_state, ''
          this.initial_history_state = ''

        window.history.pushState
          url: options.url
          data: options.data
          type: options.type
        ,'', options.url

      else
        this.ignore_hash_change = true  # avoids loading the page for hash changes caused by link clicks
        hash = "#{options.url.replace(new RegExp(this.protocol_with_host()), '')}"
        base_path_regexp = this.base_path_regexp()
        if base_path_regexp
          hash = hash.replace(base_path_regexp, '')
          hash = "/#{hash}" unless hash == '' or hash.indexOf('/') == 0
        window.location.hash = hash
#        this.ignore_hash_change = false


  base_path_regexp: ->
    return null unless this.base_paths
    # match starting and ending with base path, e.g. "^\/en$" (i.e. we are at the base path root) or
    # starting with base path and continuing with '/', e.g. "^\/en\/" (i.e. we are NOT at the base path root)
    self = this
    new RegExp("^\/(#{ $.map(this.base_paths, (el) ->
      el = self.regexp_escape el
      "#{el}$|#{el}\/|#{el}\\?"
    ).join('|')})", 'i')


  regexp_escape: (str) ->
    str.replace new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\-]', 'g'), '\\$&'


  protocol_with_host: ->
    loc = window.location
    "#{loc.protocol}//#{loc.host}"


  correct_url: ->
    if this.active
      if window.location.hash.indexOf('#/') == 0
        if !window.history.pushState
          Ajaxify.load_page_from_hash = true   # notify Ajaxify that a hash will be loaded and ignore all other calls to load until hash url is loaded
        else
          path = window.location.pathname + window.location.hash.replace(/#\//, "")       # load proper url in case url contains #/ and browser supports history api
          window.location.href = "#{this.protocol_with_host()}#{path}"

      else if !window.history.pushState
        # move path behind # for browsers without history api
        if window.location.pathname != '/'
          base_path_regexp = this.base_path_regexp()
          if base_path_regexp and (match = window.location.pathname.match(base_path_regexp))
            if match[0] == window.location.pathname
              if window.location.search == ''
                return
              else
                path = match[0].replace(/\?/,'') + '#'
            else
              path = "#{match[0]}##{window.location.pathname}"
          else
            path = "/##{window.location.pathname}"

          window.location.href = "#{this.protocol_with_host()}#{path}#{window.location.search}"
        else
          if window.location.search != ''
            window.location.href = "#{this.protocol_with_host()}/##{window.location.search}" # move search behind #

  init: ->
    this.correct_url()

  is_string: (variable) ->
    Object.prototype.toString.call(variable) == '[object String]'


jQuery ->
  Ajaxify.ajaxify()