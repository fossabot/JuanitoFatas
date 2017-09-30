class PostsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index, :show]

  def index
    @posts = Post.newest_first
    set_surrogate_key_header Post.table_key, @posts.map(&:cache_key)
  end

  def show
    @post = Post.find_by!(slug: params[:id])
    set_surrogate_key_header @post.cache_key
  end
end
