class PlaylistsController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    @playlist = Playlist.find_by!(slug: params[:slug])
  end
end
