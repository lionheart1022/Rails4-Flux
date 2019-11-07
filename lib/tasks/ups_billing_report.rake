# The tasks below are mainly there for debugging purposes. They don't mutate
# data, instead they generate a report of the parsed data.

namespace :ups_billing_report do
  task :ftp, [:file_name] => [:environment] do |t, args|
    ftp_uri = URI(ENV.fetch("UPS_BILLING_FTP"))
    zip_result = UPSBillingFTP.parse_zip_from_ftp(ftp_uri: ftp_uri, file_name: args[:file_name])
    UPSBillingReport.print_from_zip_result(zip_result)
  end

  task :local, [:file_name] => [:environment] do |t, args|
    zip_result = UPSBillingFTP.parse_zip(args[:file_name])
    UPSBillingReport.print_from_zip_result(zip_result)
  end

  task :list, [] => [:environment] do |t, args|
    ftp_uri = URI(ENV.fetch("UPS_BILLING_FTP"))
    puts UPSBillingFTP.list_ftp_files(ftp_uri: ftp_uri)
  end
end
