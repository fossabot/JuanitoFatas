class PostsController < ApplicationController
  def index
    @posts = Post.newest_first
  end

  def show
    @post = Post.find_by!(slug: params[:id])
  end
end
