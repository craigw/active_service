class ServiceClientGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory "app/models/service/client"
      m.template "models/client.erb", "app/models/service/#{service_name}_client.rb"
      m.directory "script/service/#{service_name}"
      m.template "script/service/find.erb", "script/service/#{service_name}/find"
    end
  end

  def service_name
    class_name.underscore.downcase
  end
end