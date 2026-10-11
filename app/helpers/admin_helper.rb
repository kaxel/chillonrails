module AdminHelper
  ADMIN_TIME_ZONE = "Pacific Time (US & Canada)".freeze

  # Times on admin pages are shown in Pacific time, where the station is.
  def admin_time(time)
    time.in_time_zone(ADMIN_TIME_ZONE).strftime("%b %-d, %Y · %-l:%M %p %Z")
  end
end
