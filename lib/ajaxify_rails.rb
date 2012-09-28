require "ajaxify_rails/version"

module AjaxifyRails

  module Rails
    class Engine < ::Rails::Engine
    end
  end

  ActiveSupport.on_load(:action_controller) do
    include ActionControllerAdditions
  end

  module ActionControllerAdditions

    def self.included(controller)
      controller.class_eval do

        private

        def ajaxified?
          request.xhr? and params[:ajaxified]
        end


        def render *args, &block
          if ajaxified?
            args = _normalize_args(*args, &block)
            layout = args[:layout] || current_layout
            layout = (layout == 'application' or layout == true) ? false : layout
            args[:layout] = layout

            flash.keys.each do |key|
              cookies["flash_#{key}"] = flash[key]
              flash[key] = nil
            end

            extra_content = (respond_to?(:ajaxify_extra_content) ? ajaxify_extra_content : '')

            super args

            # Store current path for redirect url changes. Also used to remove the ajaxify parameter that gets added to some auto generated urls
            # like e.g. pagination links see (ajaxify.js -> on_ajaxify_success())
            #
            current_url_tag = view_context.content_tag(:span, request.fullpath.sub(/\?ajaxified=true&(.*)/, '?\1').sub(/(&|\?)ajaxified=true/, ''),
                                                       id: 'ajaxify_location')

            response_body[0] += view_context.content_tag(:div, current_url_tag + extra_content,
                                                         id: 'ajaxify_content', style: 'display:none',
                                                         data: { page_title: respond_to?(:page_title) ? page_title : nil })
            response.body = self.response_body[0]
            return
          end
          super
        end


        def current_layout
          return @current_layout if @current_layout
          @current_layout = _layout
          @current_layout = File.basename(@current_layout.identifier).split('.').first unless @current_layout.instance_of? String
          @current_layout
        end


        def redirect_to(options = {}, response_status = {})
          request.referer.sub!('#/', '') if request.referer  # make redirect to back work for browsers without history api

          super

          ajaxify_params = "ajaxified=true&ajaxify_redirect=true"
          self.location += "#{self.location =~ /\?/ ? '&' : '?'}#{ajaxify_params}" if request.xhr?  # to avoid the full layout from being rendered
        end


        def ajaxify_redirect_to url
          render inline: "<%= javascript_tag(\"Ajaxify.load({url: '#{url}'});\") %>", layout: true
        end
      end

    end
  end

end
