module Dashboard
	class MetricsController < ApplicationController
		def index
		end

		def aggregate
			metrics = ::Ezmetrics::Storage.new(params[:interval])
			render json: { simple: simple(metrics), partitioned: partitioned(metrics) }
		end

		private

		def partition
			return :minute unless %W[second minute hour].include?(params[:partition].to_s)
			params[:partition].to_sym
		end

		def simple(metrics)
			normalized = normalize(:overview_metrics)
			return [] if normalized.blank?
			metrics.show(normalized)
		end

		def partitioned(metrics)
			normalized = normalize(:graph_metrics)
			return [] if normalized.blank?
			metrics.partition_by(partition).flatten.show(normalized)
		end

		def normalize(metrics_type)
			params[metrics_type].split(",").group_by do |p|
				p.split("_").first
			end.inject({}) do |result, (metric, values)|
				result[metric.to_sym] = values.map { |value| value.match(/\_(\w+)/)[1].to_sym }
				result
			end
		end
	end
end
