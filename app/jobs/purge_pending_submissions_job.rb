class PurgePendingSubmissionsJob < ApplicationJob
  queue_as :default

  # Removes stale unpaid submissions and their uploaded audio. Because files are
  # uploaded to S3 before payment, an abandoned Stripe checkout leaves a
  # `pending` submission with orphaned blobs; this reclaims them.
  #
  # Destroying each record (rather than delete_all) fires the dependent
  # associations so attached audio is purged from storage.
  def perform(older_than_hours = 24)
    cutoff = older_than_hours.to_i.hours.ago
    Submission.pending.where(created_at: ..cutoff).find_each(&:destroy)
  end
end
