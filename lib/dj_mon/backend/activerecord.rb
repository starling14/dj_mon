module DjMon
  module Backend
    module ActiveRecord
      module LimitedProxy
        class << self
          def method_missing(method, *args, &block)
            scope = ::DjMon::Backend::ActiveRecord.send(method, *args, &block)
            limit = Rails.configuration.dj_mon.results_limit
            limit.present? ? scope.order('id DESC').limit(limit) : scope.order('id DESC')
          end

          def respond_to?(method)
            super || ::DjMon::Backend::ActiveRecord.respond_to?(method)
          end
        end
      end

      class << self
        def limited
          LimitedProxy
        end

        def all
          Delayed::Job.all
        end

        def failed
          Delayed::Job.where('failed_at IS NOT NULL')
        end

        def active
          Delayed::Job.where('failed_at IS NULL AND locked_by IS NOT NULL')
        end

        def queued
          Delayed::Job.where('failed_at IS NULL AND locked_by IS NULL')
        end

        def destroy id
          dj = Delayed::Job.find(id)
          dj.destroy if dj
        end

        def retry id
          Delayed::Job.find(id).try do |job|
            job.update_attributes(attempts: 0, run_at: 5.seconds.ago, failed_at: nil)
          end
        end

        def reset_all
          Delayed::Job.update_all(attempts: 0, run_at: 5.seconds.ago, failed_at: nil)
        end

      end
    end
  end
end
