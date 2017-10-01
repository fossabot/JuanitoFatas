# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#index"

  get "blog" => "posts#index"
  get "blog/*id" => "posts#show", as: :blog_post
  get "tags" => "tags#index"
  get "tags/:id" => "tags#show", as: :tag
  get "quotes" => "quotes#index"
  get "contributions" => "contributions#index"
  get "are-you-with-me" => "health_checks#show"
end
