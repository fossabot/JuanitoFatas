class NowsController < ApplicationController
  def show
    @now_post = NowPost.new
  end
end
