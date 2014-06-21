module AuthsHelper
  def providers
    result = []
    <% providers.each do |provider| %>
    result << :<%= formatted_providers[provider] %> 
    <% end %>
    result
  end

  def provider_font_awesome_icon(provider)
    icon_names = HashWithIndifferentAccess.new
    <% providers.each do |provider| %>
    icon_names[:<%= provider %>] = "<%= font_awesome_icons[provider] %>"
    <% end %>
    icon_names[provider]
  end

  def provider_formatted_name(provider)
    formatted_names = HashWithIndifferentAccess.new
    <% providers.each do |provider| %>
    formatted_names[:<%= provider %>] = "<%= formatted_providers[provider] %>"
    <% end %>
    formatted_names[provider]
  end
end

