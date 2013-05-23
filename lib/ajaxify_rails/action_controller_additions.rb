module ActionControllerAdditions

  def self.included(controller)
    controller.class_eval do

      hide_action :page_title, :ajaxify_extra_content, :ajaxify_add_meta_tags, :ajaxify_set_asset_digest_header, :ajaxified?

      # override in your controller
      def page_title
        nil
      end

      # override in your controller
      def ajaxify_extra_content
        ''
      end


      def ajaxify_add_meta_tags
        ajaxify_add_meta_tag( ajaxify_assets_digest_meta_tag )

        # Correcting urls for non history api browsers wont work for post requests so add a meta tag to the response body to communicate this to
        # the ajaxify javascript
        ajaxify_add_meta_tag( view_context.tag(:meta, name: 'ajaxify:dont_correct_url', content: 'true') ) if request.post?
      end


      def ajaxify_set_asset_digest_header
        response.headers['Ajaxify-Assets-Digest'] = ajaxify_assets_digest
      end


      def ajaxified?
        request.xhr? and params[:ajaxified]
      end


      def render *args, &block
        if ajaxified?
          args = _normalize_args(*args, &block)
          layout = args[:layout] || current_layout
          layout = (layout == 'application' or layout == true or layout == false) ? false : layout
          args[:layout] = layout

          flashes = {}
          flash.keys.each do |key|
            flashes[key] = flash[key]
            flash[key] = nil
          end

          extra_content = ajaxify_extra_content

          super args

          # Store current path for redirect url changes. Also used to remove the ajaxify parameter that gets added to some auto generated urls
          # like e.g. pagination links see (ajaxify.js -> on_ajaxify_success())
          #
          current_url_tag = view_context.content_tag(:span, remove_ajaxify_param(request.fullpath),
                                                     id: 'ajaxify_location')

          response_body[0] += view_context.content_tag(:div, current_url_tag + extra_content,
                                                       id: 'ajaxify_content', style: 'display:none',
                                                       data: { page_title: page_title,
                                                               flashes: flashes.to_json,
                                                               container: args[:ajaxify_container] } )
          response.body = response_body[0]
          ajaxify_set_asset_digest_header

          return
        end

        super

        ajaxify_add_meta_tags unless request.xhr?

        return
      end


      def current_layout
        return @current_layout if @current_layout
        @current_layout = _layout
        return @current_layout if @current_layout == false
        @current_layout = File.basename(@current_layout.identifier).split('.').first unless @current_layout.instance_of? String
        @current_layout
      end


      def redirect_to(options = {}, response_status = {})
        request.referer.sub!('#/', '') if request.referer  # make redirect to back work for browsers without history api

        super

        if ajaxified?
          ajaxify_params = "ajaxified=true&ajaxify_redirect=true"
          self.location += "#{self.location =~ /\?/ ? '&' : '?'}#{ajaxify_params}" # avoid the full layout from being rendered
        end
      end


      def ajaxify_redirect_to url
        render inline: "<%= javascript_tag(\"Ajaxify.load({url: '#{url}'});\") %>", layout: true
      end


      def remove_ajaxify_param url
        url.sub(/\?ajaxified=true&(.*)/, '?\1').
            sub(/(&|\?)ajaxified=true/, '')
      end

      # Meta tag for asset change detection - inspired by wiselinks
      #
      def ajaxify_assets_digest_meta_tag
        view_context.tag(:meta, name: 'ajaxify:assets-digest', content: ajaxify_assets_digest)
      end

      def ajaxify_assets_digest
        digests = Rails.application.config.assets.digests
        digests ? Digest::MD5.hexdigest(digests.values.join) : ''
      end

      def ajaxify_add_meta_tag meta_tag
        response.body = response_body[0].sub('<head>', "<head>\n    #{meta_tag}")
      end

    end

  end

end