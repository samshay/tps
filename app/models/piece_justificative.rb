class PieceJustificative < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_piece_justificative
  has_one :commentaire

  belongs_to :user

  delegate :api_entreprise, :libelle, :order_place, to: :type_de_piece_justificative

  alias_attribute :type, :type_de_piece_justificative_id

  mount_uploader :content, PieceJustificativeUploader
  validates :content, :file_size => {:maximum => 3.megabytes}
  validates :content, presence: true, allow_blank: false, allow_nil: false

  def empty?
    content.blank?
  end

  def content_url
    unless content.url.nil?
      if Features.remote_storage
        (RemoteDownloader.new content.filename).url
      else
        (LocalDownloader.new content.path,
                             (type_de_piece_justificative.nil? ? content.original_filename : type_de_piece_justificative.libelle)).url
      end
    end
  end

  def self.accept_format
    " application/pdf,
      application/msword,
      application/vnd.openxmlformats-officedocument.wordprocessingml.document,
      application/vnd.ms-excel,
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,
      application/vnd.ms-powerpoint,
      application/vnd.openxmlformats-officedocument.presentationml.presentation,
      application/vnd.oasis.opendocument.text,
      application/vnd.oasis.opendocument.presentation,
      application/vnd.oasis.opendocument.spreadsheet,
      image/png,
      image/jpeg
    "
  end
end
