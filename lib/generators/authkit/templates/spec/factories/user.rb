FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user-#{n}@example.com" }
    <% if username? %>sequence(:username) { |n| "user-#{n}" }
    <% end %>password "example"
    password_confirmation "example"
    first_name "John"
    last_name "Example"
  end
end

