require 'spec_helper'

describe SingleUseLinksViewerController, :type => :controller do

  context "#presenter_class" do
    it 'should be Hydranorth::GenericFilePresenter' do
      expect(SingleUseLinksViewerController.presenter_class).to be Hydranorth::GenericFilePresenter
    end
  end
end
