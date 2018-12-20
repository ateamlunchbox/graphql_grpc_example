class GraphqlSchema
  def self.get_instance
    GraphQL::Schema.from_definition(
      proxy.to_gql_schema,
      default_resolve: GraphqlGrpc::Resolver.new(proxy)
    )
  end

  def self.ruby_robot_service
    ::RubyRobot::RubyRobot::Stub.new('localhost:31310', :this_channel_is_insecure)
  end

  # def self.call(type, field, obj, args, ctx)
  #   # TODO: pass in context info?
  #   get_instance.execute(field)
  # end
  #
  def self.proxy
    @proxy ||= begin
      services = { ruby_robot_service: ruby_robot_service }
      GraphqlGrpc::Proxy.new(
        services,
        &lambda do |error| 
          Rails.logger.error "Error in proxy"
          error.backtrace.each { |i| Rails.logger.error(i) }
          Rails.logger.error error
        end
      )
    end
  end
end
