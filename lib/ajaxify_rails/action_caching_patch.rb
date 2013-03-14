require 'active_support/core_ext/module/qualified_const'

# Makes Ajaxify work properly with action cached actions.
if ActionController.qualified_const_defined?("Caching::Actions::ActionCacheFilter")
	module ActionController
	  module Caching
	    module Actions

	      protected

	        class ActionCacheFilter #:nodoc:

	        	alias_method :original_filter, :filter

	          def filter(controller)
							original_filter controller
	            controller.ajaxify_add_meta_tags unless controller.request.xhr?
	            controller.ajaxify_set_asset_digest_header if controller.ajaxified?
	          end
	        end

	    end
	  end
	end
end