FactoryBot.define do
  factory :region do
    name { Faker::Lorem.unique.words.join(' ') }
  end
end
