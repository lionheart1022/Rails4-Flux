class CarrierFeedbackJob < ActiveJob::Base
  queue_as :imports

  def perform(id, auto_process: false)
    feedback_file = CarrierFeedbackFile.find(id)
    feedback_file.parse!
    feedback_file.package_updates.each(&:apply_change!) if auto_process
  end
end
