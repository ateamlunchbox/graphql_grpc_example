require 'graphql'
require 'graphql_grpc'
require 'ruby_robot'

module ActiveSupport::ToJsonWithActiveSupportEncoder
  Rails.logger.warn "ATTENTION: In order to get GraphQL working w/ gRPC, ActiveSupport::ToJsonWithActiveSupportEncoder#to_json HAS BEEN REMOVED.  You have been warned."
  begin
    remove_method :to_json
  rescue
  end
end

class GraphqlGrpcController < ApplicationController

  def graphql
    # Initial version does not allow schema queries w/ gRPC queries
    if params['query'].include?('__schema')
      handle_schema_query
    else
      handle_data_query
    end
  rescue StandardError => e
    Rails.logger.error "#{e}: #{e.backtrace.join("\n")}"
    render json: { error: e }.to_json, status: 500
  end

  private

  def handle_schema_query
    schema = GraphQL::Schema.from_definition(proxy.to_gql_schema)
    Rails.logger.debug schema.to_json
    render json: schema.execute(params['query'], {})
  end

  def handle_data_query
    Rails.logger.debug "Got query params: '#{params['query']}'"
    gql_query_doc = params['query']
    Rails.logger.debug "Calling proxy with: '#{gql_query_doc}'"
    document = GraphQL::Language::Parser.parse(gql_query_doc)
    # TODO: support passing GraphQL context info
    render json: proxy.graphql.execute(document, {})
  end

  def ruby_robot_service
    ::RubyRobot::RubyRobot::Stub.new('localhost:31310', :this_channel_is_insecure)
  end

  def proxy
    return @proxy if @proxy

    services = { ruby_robot_service: ruby_robot_service }

    @proxy = GraphqlGrpc::Proxy.new(
      services, 
      &lambda do |error| 
        Rails.logger.error "Error in proxy"
        error.backtrace.each { |i| Rails.logger.error(i) }
        Rails.logger.error error
      end
    )
  end
  
  # Extract GraphQL variables from the payload
  def graphql_variables
    return @variables if @variables
    @variables = params['variables'] == 'null' ? nil : params['variables']
    @variables.is_a?(String) ? JSON.parse(@variables) : (@variables || {})
  rescue JSON::ParserError => e
    Rails.logger.error "Error parsing GraphQL variables: #{e}"
    {}
  end
end
