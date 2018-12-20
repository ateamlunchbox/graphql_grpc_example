require 'graphql'
require 'graphql_grpc'
require 'ruby_robot'
require 'graphql_schema'

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
    Rails.logger.debug schema.to_json
    render json: schema.execute(params['query'], {})
  end

  def handle_data_query
    Rails.logger.debug "Got query params: '#{params['query']}'"
    gql_query_doc = params['query']
    Rails.logger.debug "Calling proxy with: '#{gql_query_doc}'"
    document = GraphQL::Language::Parser.parse(gql_query_doc)
    # TODO: support passing GraphQL context info
    render json: schema.execute(gql_query_doc, {})
  end

  def schema
    @schema ||= ::GraphqlSchema.get_instance
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
