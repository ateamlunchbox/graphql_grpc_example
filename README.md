# graphql_grpc_example
Example Ruby on Rails application exposing a gRPC service as a GraphQL schema using graphql_grpc.  It provides a GraphQL interface to the gRPC service found in the 'ruby_robot' rubygem (`gem install ruby_robot`).

This repository contains a bare-bones RoR application.

# Usage

* Clone the repo
* `bundle install`
* In one terminal, start up the gRPC server included with the `ruby_robot` gem: `ruby_robot_grpc_server`
* In another terminal, start up rails: `rails s`
* Browse to http://localhost:/3000/graphiql to view and exercise the GraphQL schema using the GraphiQL GUI