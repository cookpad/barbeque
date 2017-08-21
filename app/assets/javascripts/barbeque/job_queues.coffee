jQuery(($) ->
  if !document.querySelector('.barbeque_job_queues_controller')
    return
  sqsDiv = document.getElementById('sqs-attributes')
  if !sqsDiv
    return

  createTable = (div, title, metricsUrl, data) =>
    table = document.createElement('table')
    table.classList.add('table')
    table.classList.add('table-bordered')
    h4 = document.createElement('h4')
    h4.appendChild(document.createTextNode(title))
    thead = document.createElement('thead')
    theadTr = document.createElement('tr')
    thead.appendChild(theadTr)
    tbody = document.createElement('tbody')
    tbodyTr = document.createElement('tr')
    tbody.appendChild(tbodyTr)
    for own name, value of data.attributes
      th = document.createElement('th')
      th.appendChild(document.createTextNode(name))
      theadTr.appendChild(th)
      td = document.createElement('td')
      td.appendChild(document.createTextNode(value))
      tbodyTr.appendChild(td)
    table.appendChild(thead)
    table.appendChild(tbody)

    indicator = div.querySelector('.loading-indicator')
    if indicator
      indicator.parentNode.removeChild(indicator)
    div.appendChild(h4)
    div.appendChild(table)

    metrics = {
      NumberOfMessagesSent: 'Sum',
      ApproximateNumberOfMessagesVisible: 'Sum',
      ApproximateNumberOfMessagesNotVisible: 'Sum',
      ApproximateAgeOfOldestMessage: 'Maximum',
    }
    row = document.createElement('div')
    row.classList.add('row')
    div.appendChild(row)
    for own metricName, statistic of metrics
      $.getJSON("#{metricsUrl}?queue_name=#{data.queue_name}&metric_name=#{metricName}&statistic=#{statistic}").done((data) =>
        renderChart(row, data)
      ).fail((jqxhr) =>
        errorMessage = document.createElement('div')
        errorMessage.classList.add('alert')
        errorMessage.classList.add('alert-danger')
        errorMessage.appendChild(document.createTextNode("Failed to load SQS metrics #{metricName}: #{jqxhr.status}: #{jqxhr.statusText}"))

        div.appendChild(errorMessage)
      )

  url = sqsDiv.dataset.url
  metricsUrl = sqsDiv.dataset.metricsUrl
  $.getJSON(url).done((data) =>
    createTable(sqsDiv, 'Queue', metricsUrl, data)
    if data.dlq
      dlqDiv = document.getElementById('sqs-dlq-attributes')
      createTable(dlqDiv, 'Dead-letter queue', metricsUrl, data.dlq)
  ).fail((jqxhr) =>
    errorMessage = document.createElement('div')
    errorMessage.classList.add('alert')
    errorMessage.classList.add('alert-danger')
    errorMessage.appendChild(document.createTextNode("Server returned #{jqxhr.status}: #{jqxhr.statusText}"))

    indicator = sqsDiv.querySelector('.loading-indicator')
    if indicator
      indicator.parentNode.removeChild(indicator)
    sqsDiv.appendChild(errorMessage)
  )
)

renderChart = (row, data) ->
  div = document.createElement('div')
  div.classList.add('col-md-3')
  chartDiv = document.createElement('div')
  div.appendChild(chartDiv)
  div.dataset.label = data.label

  # Insert charts ordered by label name
  inserted = false
  for child in row.children
    if data.label < child.dataset.label
      row.insertBefore(div, child)
      inserted = true
      break
  if !inserted
    row.appendChild(div)

  Plotly.plot(chartDiv, [{
    type: 'scatter',
    x: data.datapoints.map((point) => point.timestamp),
    y: data.datapoints.map((point) => point.value),
  }], {
    title: data.label,
  })
