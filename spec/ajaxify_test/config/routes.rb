AjaxifyTest::Application.routes.draw do
  get "home/index"

  get "home/page1"

  get "home/page2"
  post "home/page2"

  get "home/page3"

  root :to => 'home#index'
end
