class Admin::PrevisualisationsController < AdminController
  before_action :retrieve_procedure

  def show
    @procedure
    @dossier = Dossier.new(id: 0, procedure: @procedure)

    PrevisualisationService.destroy_all_champs @dossier
    @dossier.build_default_champs

    @champs = @dossier.ordered_champs
  end
end