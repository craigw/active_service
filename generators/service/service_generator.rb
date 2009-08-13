class ServiceGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory "app/models/service"
      m.template "models/service.erb", "app/models/service/#{service_name}_service.rb"
      m.directory "script/service/#{service_name}"
      m.template "script/service.erb", "script/service/#{service_name}/service"
    end
  end

  def service_name
    class_name.underscore.downcase
  end
end