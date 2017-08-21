jQuery(($) ->
  if !document.querySelector('.barbeque_job_queues_controller')
    return
  sqsDiv = document.getElementById('sqs-attributes')
  if !sqsDiv
    return

  url = sqsDiv.dataset.url
  metricsUrl = sqsDiv.dataset.metricsUrl
  $.getJSON(url).done((data) =>
    renderBox(sqsDiv, 'SQS queue metrics', metricsUrl, data)
    if data.dlq
      dlqDiv = document.getElementById('sqs-dlq-attributes')
      renderBox(dlqDiv, 'SQS dead-letter queue metrics', metricsUrl, data.dlq)
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

renderBox = (div, title, metricsUrl, data) =>
  box = document.createElement('div')
  box.classList.add('box')
  boxHeader = document.createElement('div')
  boxHeader.classList.add('box-header')
  boxTitle = document.createElement('h3')
  boxTitle.classList.add('box-title')
  boxTitle.classList.add('with_padding')
  boxTitle.appendChild(document.createTextNode(title))
  boxHeader.appendChild(boxTitle)
  boxBody = document.createElement('div')
  boxBody.classList.add('box-body')
  box.appendChild(boxHeader)
  box.appendChild(boxBody)

  table = document.createElement('table')
  table.classList.add('table')
  table.classList.add('table-bordered')
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
  boxBody.appendChild(table)

  indicator = div.querySelector('.loading-indicator')
  if indicator
    indicator.parentNode.removeChild(indicator)
  div.appendChild(box)

  metrics = {
    NumberOfMessagesSent: 'Sum',
    ApproximateNumberOfMessagesVisible: 'Sum',
    ApproximateNumberOfMessagesNotVisible: 'Sum',
    ApproximateAgeOfOldestMessage: 'Maximum',
  }
  row = document.createElement('div')
  row.classList.add('row')
  boxBody.appendChild(row)
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
