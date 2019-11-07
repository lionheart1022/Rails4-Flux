class FedExShipperLib
  class TempPdfLabel
    attr_reader :unique_shipment_id, :label_image_blobs

    def initialize(unique_shipment_id, label_image_blobs)
      @unique_shipment_id = unique_shipment_id
      @label_image_blobs = label_image_blobs
    end

    def combined_awb_pdf
      open_pdf_temp_files do |temp_files|
        combine_pdfs_into_one(temp_files) do |pdf_file_path|
          scale_pdf_to_a4(pdf_file_path) do |cropped_pdf_path|
            yield cropped_pdf_path
          end
        end
      end
    end

    private

    def open_pdf_temp_files
      temp_files = label_image_blobs.map do |encoded_image|
        Tempfile.open(SecureRandom.uuid) do |tmp_file|
          tmp_file.write(Base64.decode64(encoded_image))
          tmp_file
        end
      end

      yield temp_files
    ensure
      Array(temp_files).each(&:delete)
    end

    def combine_pdfs_into_one(pdf_temp_files)
      all_label_pdf_paths = pdf_temp_files.map(&:path).join("  ")
      uncropped_pdf_path = [SecureRandom.uuid, "-uncropped"].join
      system("gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=#{uncropped_pdf_path} #{all_label_pdf_paths}", out: File::NULL)
      if $? != 0
        fail BookingLib::Errors::AwbDocumentFailedException.new(error_code: FedExShipperLib::Errors::COULD_NOT_SCALE_LABEL, errors: ["Could not scale pdf label to a4 with Ghostscript"])
      end
      yield uncropped_pdf_path
    ensure
      delete_file(uncropped_pdf_path)
    end

    def scale_pdf_to_a4(uncropped_pdf_path)
      new_pdf_path = [SecureRandom.uuid, unique_shipment_id, 'pdf'].join('.')
      system("gs -o #{new_pdf_path} -sDEVICE=pdfwrite -sPAPERSIZE=a4 -dFIXEDMEDIA -dPDFFitPage -dCompatibilityLevel=1.4 #{uncropped_pdf_path}")
      if $? != 0
        fail BookingLib::Errors::AwbDocumentFailedException.new(error_code: FedExShipperLib::Errors::COULD_NOT_TRIM_LABEL, errors: ["Could not trim pdf labels for FedEX shipment with Ghostscript"])
      end
      yield new_pdf_path
    ensure
      delete_file(new_pdf_path)
    end

    def delete_file(file_path)
      if file_path && File.exists?(file_path)
        File.delete(file_path)
      end
    end
  end
end
