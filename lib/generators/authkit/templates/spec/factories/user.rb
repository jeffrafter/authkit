FactoryGirl.define do
  factory :user do
    email "test@example.com"
    username "test"
    password "example"
    password_confirmation "example"
    first_name "John"
    last_name "Example"
  end
end

