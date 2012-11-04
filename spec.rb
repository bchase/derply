require './app'
require 'rspec'
require 'rack/test'

set :environment, :test

describe 'Link Shortener' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe LinkNameString do
    describe '#next' do
      subject { lns.next! }

      # context 'for 0..8' do
      #   let(:lns){ LinkNameString.new('0') } 

      #   it 'should increment the digit' do
      #     ('0'..'8').each do |i|
      #       i.should eq(lns)
      #       lns.next!
      #     end
      #   end
      # end

      # context 'for a..y' do
      #   let(:lns){ LinkNameString.new('a') } 

      #   it 'should increment the lowercase character' do
      #     ('a'..'y').each do |l|
      #       l.should eq(lns)
      #       lns.next!
      #     end
      #   end
      # end

      # context 'for A..Y' do
      #   let(:lns){ LinkNameString.new('A') } 

      #   it 'should increment the uppercase character' do
      #     ('A'..'Y').each do |u|
      #       u.should eq(lns)
      #       lns.next!
      #     end
      #   end
      # end

      # context 'when lns is "9"' do
      #   let(:lns){ LinkNameString.new('9') } 

      #   it { should eq ('a') }
      # end

      # context 'when lns is "z"' do
      #   let(:lns){ LinkNameString.new('z') } 

      #   it { should eq ('A') }
      # end

      # context 'when lns is "Z"' do
      #   let(:lns){ LinkNameString.new('Z') } 

      #   it { should eq ('00') }
      # end

      context 'when lns is "00"' do
        let(:lns){ LinkNameString.new('00') } 

        it { should eq ('01') }
      end
    end
  end

  # describe Link do
  # end
  # describe LinkNameChar do
  # end

  describe 'routes' do
    describe 'root' do
      it "success" do
        pending
        get '/'
        last_response.should be_ok
      end
    end
  end
end
