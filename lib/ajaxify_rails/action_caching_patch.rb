# Makes Ajaxify work properly with action cached actions.
module ActionController
  module Caching
    module Actions

      protected

        class ActionCacheFilter #:nodoc:

        	alias_method :original_filter, :filter

          def filter(controller)
						original_filter controller
            controller.ajaxify_add_meta_tags
          end
        end

    end
  end
end