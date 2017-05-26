require 'jira-ruby'

def ellips(s, len=40)
  s[0..len].gsub(/\s\w+\s*$/,'...')
end

jira_options = {
    :username     => '',
    :password     => '',
    :site         => 'https://backlog.acquia.com/rest/api/2/',
    :context_path => '',
    :auth_type    => :basic
}
$jira = JIRA::Client.new(jira_options)

def jira_get_issues(query, limit)
  #query = 'project = Installers AND labels in (DD3) and status = Open ORDER BY key DESC'
  issues = []
  $jira.Issue.jql(jql=query, options={fields:[:summary], max_results:limit}).each do |issue|
    issues << {key: issue.key, summary: issue.summary}
  end
  return issues
end


def get_table_data
  issues = jira_get_issues('project = Installers AND labels in (DD3) and status = Open ORDER BY key DESC', 30)
  rows = []
  i = 0
  issues.each { |issue|
    c1 = {value: issue[:key], class:'left'}
    c2 = {value: ellips(issue[:summary]), class: 'left'}
    rows << { cols: [ c1, c2 ]}
    i = i + 1
    if i == 5
      break
    end
  }
  return rows, issues.size - i
end


def get_chart_data
  frame_len = 120 # min
  frame_num = 3

  issue_chart = []
  (0..frame_num-1).each { |frm|
    f_beg = (frm + 1) * frame_len
    f_end = frm * frame_len

    issues = jira_get_issues("project ='OP' and type = Incident and status!='closed' and created > -#{f_beg}m and created < -#{f_end}m", 1000)
    issue_chart << issues.size
  }

  return issue_chart
end


def send_data
  hrows = [
      {
          cols: [
              {style: 'width:100px;'}
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
  labels = ['45-30', '30-15', '15-0']
  data = [
      {
          label: 'New open',
          data: get_chart_data,
          backgroundColor: [ 'rgba(255, 99, 132, 0.2)' ] * labels.length,
          borderColor: [ 'rgba(255, 99, 132, 1)' ] * labels.length,
          borderWidth: 1,
      }
  ]

  send_event('ticket-chart-data', { labels: labels, datasets: data })
end

send_data
send_data2
SCHEDULER.every '60s' do
  send_data
end
