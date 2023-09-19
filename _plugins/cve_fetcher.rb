require 'http'
require 'date'
require 'json'

puts "cve_fetcher.rb is running..."

Jekyll::Hooks.register :pages, :post_write do |page|
  if page.name == "cve.md" # Adjust the page name as needed
    # Get the configured start and end dates or use default values (last month)
    cve_start_date = Jekyll.configuration({})['cve_start_date'] || (Date.today - 1).prev_month.strftime('%Y-%m-%dT%H:%M:%S.000%:z')
    cve_end_date = Jekyll.configuration({})['cve_end_date'] || Date.today.strftime('%Y-%m-%dT%H:%M:%S.000%:z')

    # Get the maximum number of rows to display
    cve_display_rows = Jekyll.configuration({})['cve_display_rows'] || 10

    # Make a GET request to the NVD CVE API with the specified date range
    api_url = "https://services.nvd.nist.gov/rest/json/cves/2.0/?lastModStartDate=#{cve_start_date}&lastModEndDate=#{cve_end_date}"
    response = HTTP.get(api_url)

    if response.code == 200
      data = JSON.parse(response.body)

      # Process the data and build the table
      cve_table = "<table><thead><tr><th>CVE</th><th>Description</th><th>CVSS Vector</th><th>Base Score</th><th>Base Severity</th></tr></thead><tbody>"

      # Filter and display only the first 'cve_display_rows' CVEs
      data.each_with_index do |cve, index|
        break if index >= cve_display_rows

        cve_id = cve["cve"]["id"]
        description = cve["cve"]["descriptions"][0]["value"]
        cvss_vector = cve["cve"]["metrics"]["cvssMetricV31"][0]["cvssData"]["vectorString"]
        base_score = cve["cve"]["metrics"]["cvssMetricV31"][0]["cvssData"]["baseScore"]
        base_severity = cve["cve"]["metrics"]["cvssMetricV31"][0]["cvssData"]["baseSeverity"]

        cve_table += "<tr><td>#{cve_id}</td><td>#{description}</td><td>#{cvss_vector}</td><td>#{base_score}</td><td>#{base_severity}</td></tr>"
      end

      cve_table += "</tbody></table>"
      # Replace the content of the 'cve.md' page with the generated table
      page.content = cve_table
    else
      puts "Failed to fetch CVE data from NVD API."
    end
  end
end
