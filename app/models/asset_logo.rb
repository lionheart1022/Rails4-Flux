class AssetLogo < Asset
  has_attached_file :attachment,
                    path: 'assets/:id_partition/:token.:extension',
                    storage: :s3,
                    s3_credentials: "#{Rails.root}/config/s3_storage_buckets.yml"

  validates_attachment :attachment,
                       size: { less_than: 10.megabytes },
                       content_type: { content_type: Asset.image_mimetypes }
end
