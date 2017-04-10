class SnatchController < ApplicationController

  def about
  end

  def options
  end

  def link
    @response = request.env['omniauth.auth']
  end

  def fail
  end
end
