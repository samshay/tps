require 'spec_helper'

RSpec.describe CarteController, type: :controller do
  let(:dossier_id){10000}
  let(:bad_dossier_id){1000}
  let(:ref_dossier){'IATRQPQY'}
  let(:adresse){'50 avenue des champs élysées Paris 75008'}

  describe "GET #show" do
    it "returns http success" do
      get :show, :dossier_id => dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, :dossier_id => bad_dossier_id
      expect(response).to redirect_to('/start/error_dossier')
    end
  end

  describe 'POST #save_ref_api_carto' do
    context 'Aucune localisation n\'a jamais été enregistrée' do
      it {
        post :save_ref_api_carto, :dossier_id => dossier_id, :ref_dossier => ref_dossier, :back_url => ''
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description")
      }
    end

    context 'En train de modifier la localisation' do
      before do
        post :save_ref_api_carto, :dossier_id => dossier_id, :ref_dossier => ref_dossier, :back_url => 'recapitulatif'
        @last_commentaire_id = ActiveRecord::Base.connection.execute("SELECT currval('commentaires_id_seq')").getvalue(0,0)
      end

        context 'Enregistrement d\'un commentaire informant la modification' do
          subject{Commentaire.find(@last_commentaire_id)}

          it 'champs email' do
            expect(subject.email).to eq('Modification localisation')
          end

          it 'champs body' do
            expect(subject.body).to eq('La localisation de la demande a été modifiée. Merci de le prendre en compte.')
          end

          it 'champs dossier' do
            expect(subject.dossier.id).to eq(dossier_id)
          end
        end

        it 'Redirection vers la page récapitulatif' do
          expect(response).to redirect_to("/dossiers/#{dossier_id}/recapitulatif")
        end
    end
  end

  describe '#get_position' do
    before do
      stub_request(:get, "http://api-adresse.data.gouv.fr/search?limit=1&q=#{adresse}").
          to_return(:status => 200, :body => '{"query": "50 avenue des champs \u00e9lys\u00e9es Paris 75008", "version": "draft", "licence": "ODbL 1.0", "features": [{"geometry": {"coordinates": [2.306888, 48.870374], "type": "Point"}, "type": "Feature", "properties": {"city": "Paris", "label": "50 Avenue des Champs \u00c9lys\u00e9es 75008 Paris", "housenumber": "50", "id": "ADRNIVX_0000000270748251", "postcode": "75008", "name": "50 Avenue des Champs \u00c9lys\u00e9es", "citycode": "75108", "context": "75, \u00cele-de-France", "score": 0.9054545454545454, "type": "housenumber"}}], "type": "FeatureCollection", "attribution": "BAN"}', :headers => {})
      get :get_position, :dossier_id => dossier_id
    end

    context 'retour d\'un fichier JSON avec 3 attributs' do
      subject {JSON.parse(response.body)}

      it 'format JSON valide' do
        expect(response.content_type).to eq('application/json')
      end

      it 'latitude' do
        expect(subject['lat']).to eq('48.870374')
      end

      it 'longitude' do
        expect(subject['lon']).to eq('2.306888')
      end

      it 'dossier_id' do
        expect(subject['dossier_id']).to eq('10000')
      end
    end
  end
end