require_relative '.conf'
require 'jira-ruby'


=begin
.conf.rb  example

$pagerduty_options = {
    :url       => 'https://acquiaops.pagerduty.com',
    :apikey    => 'xxxxxx',
    :services  => '{"services": { "Notify-Ops-OnCall": "xxxxxx"}}',
    :schedules => '{"schedules": { "hotseat": "xxxxxx","hotseat-secondary": "xxxxxx"}}'
}

$jira_options = {
    :username     => 'dmitry.bezer',
    :password     => 'xxxxxx',
    :site         => 'https://backlog.acquia.com/rest/api/2/',
    :context_path => '',
    :auth_type    => :basic
}
=end



def ellips(s, len=40)
  s[0..len].gsub(/\s\w+\s*$/,'...')
end

$jira = JIRA::Client.new($jira_options)

def jira_get_issues(query, limit)
  #query = 'project = Installers AND labels in (DD3) and status = Open ORDER BY key DESC'
  issues = []
  $jira.Issue.jql(jql=query, options={fields:[:summary], max_results:limit}).each do |issue|
    issues << {key: issue.key, summary: issue.summary}
  end
  return issues
end


def get_table_data
  issues = jira_get_issues("project ='OP' and type = Incident and status!='closed' ORDER BY key DESC", 30)
  rows = []
  i = 0
  issues.each { |issue|
    c1 = {value: issue[:key], class:'left'}
    c2 = {value: ellips(issue[:summary], 40), class: 'left'}
    rows << { cols: [ c1, c2 ]}
    i = i + 1
    if i == 9
      break
    end
  }
  return rows, issues.size - i
end


def get_chart_data
  frame_len = 60 # min
  frame_num = 3

  chart_data = []
  chart_labels = []
  for frm in (frame_num - 1).downto(0)
    f_beg = (frm + 1) * frame_len
    f_end = frm * frame_len

    q = "project ='OP' and type = Incident and status!='closed' and created > -#{f_beg}m and created < -#{f_end}m"
    puts q
    issues = jira_get_issues(q, 1000)
    chart_data << issues.size
    chart_labels << "#{f_beg} - #{f_end}"
  end

  return chart_data, chart_labels
end


def send_data
  hrows = [
      {
          cols: [
              {style: 'width:150px;'},
              {style: 'width:430px;'}
          ]
      }
  ]

  rows, m = get_table_data
  data = { hrows: hrows, rows: rows }

  if m > 0
    data[:moreinfo] = "#{m} more..."
  end
  send_event('ticket-list-data', data )
end


def send_data2
#  labels = ['45-30', '30-15', '15-0']
  chart_data, chart_labels = get_chart_data

  data = [
      {
          label: 'New open',
          data: chart_data,
          backgroundColor: [ 'rgba(255, 99, 132, 0.2)' ] * chart_labels.length,
          borderColor: [ 'rgba(255, 99, 132, 1)' ] * chart_labels.length,
          borderWidth: 1,
      }
  ]

  send_event('ticket-chart-data', { labels: chart_labels, datasets: data })
end

send_data
send_data2
SCHEDULER.every '60s' do
  send_data
  send_data2
end
