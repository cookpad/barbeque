jQuery(($) ->
  if !document.querySelector('.barbeque_job_queues_controller')
    return
  sqsDiv = document.getElementById('sqs-attributes')
  if !sqsDiv
    return

  createTable = (div, title, data) =>
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

  url = sqsDiv.dataset.url
  $.getJSON(url).done((data) =>
    createTable(sqsDiv, 'Queue', data)
    if data.dlq
      dlqDiv = document.getElementById('sqs-dlq-attributes')
      createTable(dlqDiv, 'Dead-letter queue', data.dlq)
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
