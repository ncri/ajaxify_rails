class HomeController < ApplicationController

  before_filter :toggle_ajaxify

  def index
    sleep 0.5
  end

  def page1
    sleep 0.5
  end

  def page2
    sleep 0.5
    if request.post?
      flash.now[:notice] = "Form submitted (#{params[:input1]}, #{params[:input2]}, #{params[:check_me]})"
    end
  end

  def page3
    flash[:notice] = 'Redirected to Page 1'
    redirect_to '/home/page1'
  end


  private

  def toggle_ajaxify
    session[:ajaxify] = true if params[:ajaxify_on]
    session[:ajaxify] = false if params[:ajaxify_off]
    session[:push_state_enabled] = (params[:push_state_enabled] != 'false') if params[:push_state_enabled].present? 
  end

end
