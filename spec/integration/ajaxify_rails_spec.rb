require 'spec_helper'


steps 'Test basic behavior', :js => true do

	before(:each) do   # only executed once before all "it" blocks (see https://github.com/LRDesign/rspec-steps)
	  visit root_path(ajaxify_on: true)
	  @layout_id = find('body')['data-id']
	end

  it "should display loader" do 
    click_on 'Page 1'
    page.should have_css(".ajaxify_loader")
  end

  it "should load page's content" do    
    should_have_content 'Page 1 Content'
    push_state_path_should_be '/home/page1'
    ensure_layout_not_reloaded
  end

  it "should redirect" do
  	click_on 'Page 3 (redirects to page 1)'
  	should_have_content 'Page 1 Content'
  	push_state_path_should_be '/home/page1'
  	ensure_layout_not_reloaded
  end

  it "should display flash" do
  	should_have_notice 'Redirected to Page 1'
  end

  it "should submit a form" do
  	click_on 'Page 2'
  	fill_in 'input1', with: 'test'
  	check 'check_me'
  	push_state_path_should_be '/home/page2'
  	click_button 'Submit me'
  	should_have_notice 'Form submitted (test, , 1)'
  	ensure_layout_not_reloaded
  end

  it "should load previous content when clicking the browser back button" do
  	click_on 'Home'
  	wait_for_ajaxify_loaded
 		click_on 'Page 1'
  	wait_for_ajaxify_loaded
  	click_browser_back_button
  	should_have_content 'Home Content'
  	push_state_path_should_be '/'
  	ensure_layout_not_reloaded
	end

	it "should load next content when clicking the browser forward button" do
  	click_browser_forward_button
  	should_have_content 'Page 1 Content'
  	push_state_path_should_be '/home/page1'
  	ensure_layout_not_reloaded
	end

	it "should not repost form clicking the browser back button" do
		click_on 'Page 2'
  	click_button 'Submit me'
  	wait_for_ajaxify_loaded
  	click_on 'Page 1'
  	wait_for_ajaxify_loaded
  	click_browser_back_button
  	wait_for_ajaxify_loaded
  	page.should_not have_css("#notice", visible: true)
  	should_have_content /A Form/
  	push_state_path_should_be '/home/page2'
	end

end


steps 'Test hash based url scheme for browsers without pushState', :js => true do

	before(:each) do   # only executed once before all "it" blocks (see https://github.com/LRDesign/rspec-steps)
	  visit root_path(ajaxify_on: true, push_state_enabled: false)
	  @layout_id = find('body')['data-id']
	  #sleep 2 # poltergeist needs this
	  hash_path_should_be '/?ajaxify_on=true&push_state_enabled=false'
	end

  it "should display loader" do 
    click_on 'Page 1'
    page.should have_css(".ajaxify_loader")
  end

  it "should load page's content" do    
    should_have_content 'Page 1 Content'
    hash_path_should_be '/home/page1'
    ensure_layout_not_reloaded
  end

  it "should redirect" do
  	click_on 'Page 3 (redirects to page 1)'
  	should_have_content 'Page 1 Content'
  	hash_path_should_be '/home/page1'
  	ensure_layout_not_reloaded
  end

  it "should display flash" do
  	should_have_notice 'Redirected to Page 1'
  end

  it "should submit a form" do
  	click_on 'Page 2'
  	fill_in 'input1', with: 'test'
  	check 'check_me'
  	hash_path_should_be '/home/page2'
  	click_button 'Submit me'
  	should_have_notice 'Form submitted (test, , 1)'
  	ensure_layout_not_reloaded
  end

  it "should load previous content when clicking the browser back button" do
  	click_on 'Home'
  	wait_for_ajaxify_loaded
 		click_on 'Page 1'
  	wait_for_ajaxify_loaded
  	click_browser_back_button
  	should_have_content 'Home Content'
  	hash_path_should_be '/'
  	ensure_layout_not_reloaded
	end

	it "should load next content when clicking the browser forward button" do
  	click_browser_forward_button
  	should_have_content 'Page 1 Content'
  	hash_path_should_be '/home/page1'
  	ensure_layout_not_reloaded
	end

	it "should not repost form clicking the browser back button" do
		click_on 'Page 2'
  	click_button 'Submit me'
  	wait_for_ajaxify_loaded
  	click_on 'Page 1'
  	wait_for_ajaxify_loaded
  	click_browser_back_button
  	wait_for_ajaxify_loaded
  	page.should_not have_css("#notice", visible: true)
  	should_have_content /A Form/
  	hash_path_should_be '/home/page2'
	end

end


describe 'Test convert urls', :js => true do

	it 'should convert a hash url to a proper one in a browser supporting pushState' do
		visit root_path(ajaxify_on: true, anchor: '/home/page1')
		should_have_content 'Page 1 Content'
		push_state_path_should_be '/home/page1'
	end

	it 'should convert a proper url to a hash url in a browser not supporting pushState' do
		visit '/home/page1?ajaxify_on=true&push_state_enabled=false'
		should_have_content 'Page 1 Content'
		hash_path_should_be '/home/page1?ajaxify_on=true&push_state_enabled=false'
	end

end