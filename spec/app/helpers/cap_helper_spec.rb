require 'spec_helper'

describe "CAPWebApp::App::CAPHelper" do
  let(:helpers){ Class.new }
  before { helpers.extend CAPWebApp::App::CAPHelper }
  subject { helpers }

  it "should return nil" do
    expect(subject.foo).to be_nil
  end
end
