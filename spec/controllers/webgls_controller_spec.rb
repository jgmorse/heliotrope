# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebglsController, type: :controller do
  after { Webgl::Cache.clear }

  describe '#show' do
    context "when the file_set is a webgl" do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.unity'))) }
      before { get :show, params: { id: file_set.id } }
      it { expect(response).to have_http_status(:success) }
    end

    context "when the file_set is not a webgl" do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      before { get :show, params: { id: file_set.id } }
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe '#file' do
    context "the file_set is a webgl" do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.unity'))) }
      it "returns the UnityLoader.js file" do
        get :file, params: { id: file_set.id, file: 'Build/UnityLoader', format: 'js' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be false
      end

      it "does not return a nonexistent file" do
        get :file, params: { id: file_set.id, file: 'Build/NotAThing', format: 'js' }
        # TODO: really, shouldn't this be a 404/:not_found?
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end

      it "does not return /etc/passwd :)" do
        get :file, params: { id: file_set.id, file: '/etc/passwd', format: '' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end
  end
end