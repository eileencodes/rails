# frozen_string_literal: true

require "rails/application_controller"
require "action_dispatch/routing/inspector"

class Rails::InfoController < Rails::ApplicationController # :nodoc:
  prepend_view_path ActionDispatch::DebugView::RESCUES_TEMPLATE_PATHS
  layout -> { request.xhr? ? false : "application" }

  before_action :require_local!

  def index
    redirect_to action: :routes
  end

  def properties
    @info = Rails::Info.to_html
    @page_title = "Properties"
  end

  def models
  end

  # /columns.json?model=Post
  def columns
    columns = params[:model].constantize.columns.map { |column| [column.name.to_s, column.type.to_s] }

    respond_to do |format|
      format.json { render json: columns }
    end
  rescue
    head :not_found
  end

  def refresh
    ## hit this
  end

  def routes
    if query = params[:query]
      query = URI::DEFAULT_PARSER.escape query

      render json: {
        exact: matching_routes(query: query, exact_match: true),
        fuzzy: matching_routes(query: query, exact_match: false)
      }
    elsif query = params[:helper_info]
      route = Rails.application.routes.named_routes.get(query)

      if route
        controller = route.requirements[:controller]
        action = route.requirements[:action]

        render json: {
          action: action,
          controller: controller,
          path: route.path.spec.to_s
        }
      else
        head :not_found
      end
    else
      @routes_inspector = ActionDispatch::Routing::RoutesInspector.new(_routes.routes)
      @page_title = "Routes"
    end
  end

  private
    def matching_routes(query:, exact_match:)
      return [] if query.blank?

      normalized_path = ("/" + query).squeeze("/")
      query_without_url_or_path_suffix = query.gsub(/(\w)(_path$)/, '\1').gsub(/(\w)(_url$)/, '\1')

      _routes.routes.filter_map do |route|
        route_wrapper = ActionDispatch::Routing::RouteWrapper.new(route)

        if exact_match
          match = route.path.match(normalized_path)
          match ||= (query_without_url_or_path_suffix === route_wrapper.name)
        else
          match = route_wrapper.path.match(query)
          match ||= route_wrapper.name.include?(query_without_url_or_path_suffix)
        end

        match ||= (query === route_wrapper.verb)

        unless match
          controller_action = URI::DEFAULT_PARSER.escape(route_wrapper.reqs)
          match = exact_match ? (query === controller_action) : controller_action.include?(query)
        end

        route_wrapper.path if match
      end
    end
end
