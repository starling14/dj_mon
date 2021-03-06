module DjMon
  class DjReport
    TIME_FORMAT = "%b %d %H:%M:%S %z"

    attr_accessor :delayed_job

    def initialize delayed_job
      self.delayed_job = delayed_job
    end

    def as_json options = {}
      {
        id: delayed_job.id.to_s,
        payload: delayed_job.handler,
        priority: delayed_job.priority,
        attempts: delayed_job.attempts,
        queue: delayed_job.queue || "global",
        last_error_summary: delayed_job.last_error.to_s.truncate(80),
        last_error: delayed_job.last_error,
        failed_at: l_datetime(delayed_job.failed_at),
        run_at: l_datetime(delayed_job.run_at),
        created_at: l_datetime(delayed_job.created_at),
        failed: delayed_job.failed_at.present?
      }
    end

    class << self
      def reports_for jobs
        jobs.collect { |job| DjReport.new(job) }
      end

      def all_reports page = nil, per_page = 50
        reports_for DjMon::Backend.all(page, per_page)
      end

      def failed_reports page = nil, per_page = 50
        reports_for DjMon::Backend.failed(page, per_page)
      end

      def active_reports page = nil, per_page = 50
        reports_for DjMon::Backend.active(page, per_page)
      end

      def queued_reports page = nil, per_page = 50
        reports_for DjMon::Backend.queued(page, per_page)
      end

      def dj_counts
        {
          all: DjMon::Backend.all.size,
          failed: DjMon::Backend.failed.size,
          active: DjMon::Backend.active.size,
          queued: DjMon::Backend.queued.size
        }
      end

      def settings
        {
          destroy_failed_jobs: Delayed::Worker.destroy_failed_jobs,
          sleep_delay:         Delayed::Worker.sleep_delay,
          max_attempts:        Delayed::Worker.max_attempts,
          max_run_time:        Delayed::Worker.max_run_time,
          read_ahead:          defined?(Delayed::Worker.read_ahead) ? Delayed::Worker.read_ahead : 5,
          delay_jobs:          Delayed::Worker.delay_jobs,
          delayed_job_version: Gem.loaded_specs["delayed_job"].version.version,
          dj_mon_version:      DjMon::VERSION
        }
      end
    end

    private
    def in_time_zone time
      if Rails.configuration.dj_mon.timezone.present?
        time.in_time_zone(Rails.configuration.dj_mon.timezone)
      else
        time
      end
    end

    def l_datetime time
      time.present? ? in_time_zone(time).strftime(TIME_FORMAT) : ""
    end
  end

end
