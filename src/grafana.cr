require "http/client"
require "json"
require "semantic_version"
require "./security"

def grafana_version(hostname, headers)
  response = HTTP::Client.get("https://#{hostname}/api/health", headers)
  version = SemanticVersion.parse(JSON.parse(response.body)["version"].to_s)
  if version.major >= 8
    :v2
  else
    :v1
  end
end

def fetch_v2_alerts(hostname, headers)
  response = HTTP::Client.get("https://#{hostname}/api/alertmanager/grafana/api/v2/alerts", headers)
  alerts = JSON.parse(response.body).as_a.map { |alert| Tuple.new(hostname, alert) }
  alerts.map do |alert_and_host|
    hostname = alert_and_host[0]
    alert = alert_and_host[1]
    annotations = alert["annotations"].as_h?
    href = alert_v2_url(hostname, alert)
    if annotations && annotations.has_key?("AlertValues")
      alert_value = annotations["AlertValues"].to_s
      "#{hostname} #{alert["labels"]["alertname"]}: #{alert_value.gsub('\n', '-')} | color=#E45959 href=#{href}"
    else
      "#{hostname} #{alert["labels"]["alertname"]} | color=#E45959 href=#{href}"
    end
  end
end

def fetch_v1_alerts(hostname, headers)
  response = HTTP::Client.get("https://#{hostname}/api/alerts?state=alerting", headers)
  alerts = JSON.parse(response.body).as_a.map { |alert| Tuple.new(hostname, alert) }
  alerts.map do |alert_and_host|
    hostname = alert_and_host[0]
    alert = alert_and_host[1]
    href = "https://#{hostname}#{alert["url"]}?fullscreen&panelId=#{alert["panelId"]}"
    if alert["evalData"]
      alert["evalData"]["evalMatches"].as_a.map { |match|
        "#{hostname} #{alert["name"]}: #{match["metric"]} = #{match["value"]} | color=#E45959 href=#{href}"
      }.join("\n")
    else
      "#{hostname} #{alert["name"]} | color=#E45959 href=#{href}"
    end
  end
end

def alert_v2_url(hostname, alert)
  annotations = alert["annotations"]
  "https://#{hostname}/d/#{annotations["__dashboardUid__"]}/alerts?orgId=#{annotations["__orgId__"]}&viewPanel=#{annotations["__panelId__"]}"
end

alerts = [] of String
hostnames = {{ env("GRAFANA_HOSTS") }}.split(",")
hostnames.each { |hostname|
  apikey = Security.find_generic_password(hostname, "apikey")
  headers = HTTP::Headers{"Authorization" => "Bearer #{apikey}"}
  version = grafana_version(hostname, headers)
  # TODO: this code is ugly - but it works
  alerts += (if version == :v2
    fetch_v2_alerts(hostname, headers)
  else
    fetch_v1_alerts(hostname, headers)
  end)
}

alert_prefix = {{ env("GRAFANA_ALERT_PREFIX") }} || "Grafana: "
success_message = {{ env("GRAFANA_ALERT_SUCCESS_MESSAGE") }} || "✅"
alert_message = {{ env("GRAFANA_ALERT_ALERT_MESSAGE") }} || "‼️"

if alerts.size == 0
  puts "#{alert_prefix}#{success_message}"
else
  puts "#{alert_prefix}#{alert_message}"
end

puts "---"
hostnames.each { |hostname|
  puts "#{hostname} | href=https://#{hostname}"
}
puts "---"
puts alerts.join("\n")
