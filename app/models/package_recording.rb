class PackageRecording < ActiveRecord::Base
  belongs_to :package, required: true
end
