# frozen_string_literal: true

class Vacuum::MediaAttachmentsVacuum
  TTL = 1.day.freeze

  def initialize(retention_period)
    @retention_period = retention_period
  end

  def perform
    vacuum_orphaned_records!
    vacuum_cached_files! if retention_period?
  end

  private

  def vacuum_cached_files!
    media_attachments_past_retention_period.find_each do |media_attachment|
      media_attachment.file.destroy
      media_attachment.thumbnail.destroy
      media_attachment.save
    end
  end

  def vacuum_orphaned_records!
    orphaned_media_attachments.in_batches.destroy_all
  end

  def media_attachments_past_retention_period
    MediaAttachment
      .remote
      .cached
      .created_before(@retention_period.ago)
      .updated_before(@retention_period.ago)
  end

  def orphaned_media_attachments
    MediaAttachment
      .unattached
      .created_before(TTL.ago)
  end

  def retention_period?
    @retention_period.present?
  end
end
