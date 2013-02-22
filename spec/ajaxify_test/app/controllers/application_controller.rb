class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :page_title


  def page_title
    title = case action_name
      when 'index'
        'Home'
      when 'page1'
        'Page 1'
      when 'page2'
        'Page 2'
    end
    "Ajaxify Test - #{title}"
  end

end
