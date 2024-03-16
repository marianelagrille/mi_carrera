require 'rails_helper'

RSpec.describe Review, type: :model do
  subject { create :review }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:subject) }
  end

  describe 'validations' do
    it {
      is_expected.to validate_uniqueness_of(:user_id)
        .scoped_to(:subject_id)
        .with_message("You can only review a subject once.")
    }
    it { is_expected.to validate_presence_of(:rating) }
    it { is_expected.to validate_inclusion_of(:rating).in_range(1..5) }
  end

  describe 'callbacks' do
    context 'calls update_rating on subject after commit' do
      let(:review) { build :review }

      it 'calls update_rating on subject after create' do
        expect(review.subject).to receive(:update_rating)
        review.save!
      end

      it 'calls update_rating on subject after update' do
        review.save!
        expect(review.subject).to receive(:update_rating)
        review.update!(rating: 5)
      end

      it 'calls update_rating on subject after destroy' do
        review.save!
        expect(review.subject).to receive(:update_rating)
        review.destroy
      end
    end
  end
end
