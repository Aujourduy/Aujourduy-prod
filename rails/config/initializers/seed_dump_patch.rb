# Patch de compatibilité seed_dump pour Rails 8
# Corrige l'appel obsolète à to_s(:db) dans la gem 3.3.1

if defined?(SeedDump::DumpMethods)
  module SeedDump::DumpMethods
    def value_to_s(value)
      case value
      when Time, DateTime, ActiveSupport::TimeWithZone
        "'#{value.utc.strftime("%Y-%m-%d %H:%M:%S")}'"
      when Date
        "'#{value.strftime("%Y-%m-%d")}'"
      when String
        value.inspect
      else
        value.nil? ? 'nil' : value.to_s
      end
    end
  end
end
