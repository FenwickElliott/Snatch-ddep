class SnatchController < ApplicationController
  # require 'rest-client'
  require 'json'
  require 'net/http'
  require 'uri'

  def about
    if user_signed_in?
      puts "signed in"
      unless session[:user_id]
        puts "redirect_to link_path"
        # redirect_to link_path
      end
    else
      puts "not signed in"
    end
  end

  def options
    session[:pname] = current_user[:pname]
  end

  def update
    if params[:session][:pname] != ''
      puts "update!!!"
      current_user[:pname] = params[:session][:pname]
      current_user.save!
    end
    redirect_to options_path
  end

  def link
    session[:response] = request.env['omniauth.auth']
    session[:token] = session[:response][:credentials][:token]
    session[:header] = {
      Accept: "application/json",
      Authorization: "Authorization: Bearer #{session[:token]}"
    }
    get_me
    flash[:notice] = "You have sucsessfully linked your Spotify account"
    redirect_to root_path
  end

  def fail
  end

  def snatch
    snatch
  end

  def get(endpoint)
    JSON.parse RestClient.get("https://api.spotify.com/v1/#{endpoint}", session[:header])
  end


  def get_me
    begin
      # user = JSON.parse RestClient.get("https://api.spotify.com/v1/me", session[:header])
      user = get('me')
      session[:user_id] = user['id']
      puts "get_me complete, got #{session[:user_id]}"

    rescue
      puts "couldn't access spotify api"
      flash[:alert] = "I'm sorry, we couldn't access the Spotify API, which is problematic..."
    end
  end

  def get_song
      # song = JSON.parse RestClient.get("https://api.spotify.com/v1/me/player/currently-playing", session[:header])
      song = get('me/player/currently-playing')
      session[:s_uri] = song['item']['uri']
      session[:s_name] = song['item']['name']
    puts "get_song complete, got #{session[:s_name]}"
  end

  def check_for_playlist
    if session[:user_id]
      # list = JSON.parse RestClient.get("https://api.spotify.com/v1/me/playlists?limit=50", session[:header])
      list = get('me/playlists?limit=50')
      list['items'].each do |x|
          if x['name'] === current_user[:pname]
            puts x['name'] << ' Playlist found'
            session[:p_id] = x['id']
            return
          end
        end
        puts "check_for_playlist complete, #{current_user[:pname]} not found, creating"
        create_playlist
      end
      puts "check_for_playlist complete, #{current_user[:pname]} found"
  end

  def create_playlist
    uri = URI.parse("https://api.spotify.com/v1/users/#{session[:user_id]}/playlists")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer #{session[:token]}"
    request.body = JSON.dump({
      "description" => "Your Snatched Playlist",
      "public" => false,
      "name" => "#{current_user[:pname]}"
    })
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    playlist = JSON.parse response.body
    session[:p_id] = playlist['id']
    puts "create_playlist complete #{current_user[:pname]} playlist created. ID: #{session[:p_id]}"
  end

  def actually_snatch
    uri = URI.parse("https://api.spotify.com/v1/users/#{session[:user_id]}/playlists/#{session[:p_id]}/tracks?uris=#{session[:s_uri]}")
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer #{session[:token]}"
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    if response.code == '201'
      flash[:notice] = "#{session[:s_name]} was sucsessfully added to #{current_user[:pname]}"
    else
      flash[:alert] = "Unfortunately that didn't work. Not sure why...'"
    end
    puts "actually_snatch complete"
    redirect_to root_path
  end

  def check_through_playlist
    # playlist = JSON.parse RestClient.get("https://api.spotify.com/v1/users/#{session[:user_id]}/playlists/#{session[:p_id]}/tracks", session[:header])
    playlist = get("users/#{session[:user_id]}/playlists/#{session[:p_id]}/tracks")

    for i in 0..(playlist['items'].length - 1)
      if playlist['items'][i]['track']['uri'] === session[:s_uri]
        puts "That song has already been snatched"
        flash[:alert] = "Silly goat, #{session[:s_name]} has already been snatched"
        redirect_to root_path
        return
      end
    end
    puts "check_through_playlist complete"
    actually_snatch
  end
  
  def snatch
    get_me
    get_song
    check_for_playlist
    check_through_playlist
    # actually_snatch
  end
end
