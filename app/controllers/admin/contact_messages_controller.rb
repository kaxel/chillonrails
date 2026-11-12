module Admin
  class ContactMessagesController < BaseController
    PER_PAGE = 25

    def index
      @page_title = "messages"
      @filter = params[:filter] == "undelivered" ? "undelivered" : "all"

      messages = ContactMessage.order(created_at: :desc, id: :desc)
      messages = messages.undelivered if @filter == "undelivered"

      @total_count = ContactMessage.count
      @undelivered_count = ContactMessage.undelivered.count
      shown_count = @filter == "undelivered" ? @undelivered_count : @total_count

      @total_pages = [ (shown_count / PER_PAGE.to_f).ceil, 1 ].max
      @page = params[:page].to_i.clamp(1, @total_pages)
      @contact_messages = messages.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
    end

    def show
      @page_title = "message"
      @contact_message = ContactMessage.find(params[:id])
    end
  end
end
