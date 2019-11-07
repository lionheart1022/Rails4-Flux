class RefreshStatsJob < ActiveJob::Base
  queue_as :booking

  def perform(batch_size = 100, recursive = false, acc = {})
    next_acc_count = acc.try(:[], "acc_count") || 0
    next_acc_run_time = acc.try(:[], "acc_run_time") || 0.0
    tms = nil

    remaining_stats_that_need_refresh = AggregateShipmentStatistic.needs_refresh

    refresh_subset = remaining_stats_that_need_refresh.limit(batch_size)
    refresh_subset.load

    if refresh_subset.size > 0
      tms = Benchmark.measure { refresh_subset.each(&:refresh_monthly) }
      next_acc_count += refresh_subset.size
      next_acc_run_time += tms.real
    end

    if remaining_stats_that_need_refresh.exists?
      Rails.logger.info "Refreshing status=in_progress processed_stats=#{refresh_subset.size} run_time_in_seconds=#{tms ? sprintf('%.2f', tms.real) : '0'}"

      next_args = [
        batch_size,
        recursive,
        {
          "acc_count" => next_acc_count,
          "acc_run_time" => next_acc_run_time,
        },
      ]

      # Refresh remaining stats
      if recursive
        # The recursive version will not enqueue new jobs
        perform(*next_args)
      else
        # The non-recursive version will enqueue a new job
        self.class.perform_later(*next_args)
      end
    else
      Rails.logger.info "Refreshing status=done total_processed_stats=#{next_acc_count} total_run_time_in_seconds=#{sprintf('%.2f', next_acc_run_time)}"
    end
  end
end
