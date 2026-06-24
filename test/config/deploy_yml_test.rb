# frozen_string_literal: true

require "test_helper"
require "erb"
require "yaml"

class DeployYmlTest < ActiveSupport::TestCase
  test "production logging accessories stay lean for the small VPS" do
    accessories = deploy_config.fetch("accessories")

    assert_includes accessories, "loki"
    assert_includes accessories, "alloy"
    assert_equal "run /etc/alloy/config.alloy", accessories.dig("alloy", "cmd")
    assert_nil accessories.dig("alloy", "directories")

    assert_not_includes accessories, "otel-collector"
    assert_not_includes accessories, "tempo"
    assert_not_includes accessories, "prometheus"
    assert_not_includes accessories, "node-exporter"
    assert_not_includes accessories, "cadvisor"
    assert_not_includes accessories, "postgres-exporter"
    assert_not_includes accessories, "grafana"
  end

  test "active observability data directories are owned by their runtime container users" do
    expected_directories = {
      "loki" => { "local" => "loki_data", "remote" => "/loki", "owner" => "10001:10001" }
    }

    accessories = deploy_config.fetch("accessories")

    expected_directories.each do |accessory_name, expected|
      directory = Array(accessories.dig(accessory_name, "directories")).find do |entry|
        entry.is_a?(Hash) && entry["local"] == expected["local"]
      end

      assert_not_nil directory, "Expected #{accessory_name} to declare #{expected.fetch("local")} as a hash directory"
      assert_equal expected.fetch("remote"), directory.fetch("remote")
      assert_equal expected.fetch("owner"), directory.fetch("owner")
      assert_equal "0755", directory.fetch("mode")
    end
  end

  test "production disables opentelemetry export on the small VPS" do
    env = deploy_config.fetch("env").fetch("clear")

    assert_equal "true", env.fetch("OTEL_SDK_DISABLED")
    assert_not env.key?("OTEL_EXPORTER_OTLP_ENDPOINT")
  end

  private

  def deploy_config
    rendered_config = ERB.new(Rails.root.join("config/deploy.yml").read).result

    YAML.safe_load(rendered_config, aliases: true)
  end
end
