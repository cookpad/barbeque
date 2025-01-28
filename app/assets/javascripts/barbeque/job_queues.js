jQuery(function($) {
  if (!document.querySelector('.barbeque_job_queues_controller')) {
    return;
  }
  const sqsDiv = document.getElementById('sqs-attributes');
  if (!sqsDiv) {
    return;
  }

  const { url, metricsUrl } = sqsDiv.dataset;
  $.getJSON(url).done(data => {
    renderBox(sqsDiv, 'SQS queue metrics', metricsUrl, data);
    if (data.dlq) {
      const dlqDiv = document.getElementById('sqs-dlq-attributes');
      renderBox(dlqDiv, 'SQS dead-letter queue metrics', metricsUrl, data.dlq);
    }
  }).fail(jqxhr => {
    const errorMessage = document.createElement('div');
    errorMessage.classList.add('alert');
    errorMessage.classList.add('alert-danger');
    errorMessage.appendChild(document.createTextNode(`Server returned ${jqxhr.status}: ${jqxhr.statusText}`));

    const indicator = sqsDiv.querySelector('.loading-indicator');
    if (indicator) {
      indicator.parentNode.removeChild(indicator);
    }
    sqsDiv.appendChild(errorMessage);
  });
});

const renderBox = (div, title, metricsUrl, data) => {
  const box = document.createElement('div');
  box.classList.add('box');
  const boxHeader = document.createElement('div');
  boxHeader.classList.add('box-header');
  const boxTitle = document.createElement('h3');
  boxTitle.classList.add('box-title');
  boxTitle.classList.add('with_padding');
  boxTitle.appendChild(document.createTextNode(title));
  boxHeader.appendChild(boxTitle);
  const boxBody = document.createElement('div');
  boxBody.classList.add('box-body');
  box.appendChild(boxHeader);
  box.appendChild(boxBody);

  const table = document.createElement('table');
  table.classList.add('table');
  table.classList.add('table-bordered');
  const thead = document.createElement('thead');
  const theadTr = document.createElement('tr');
  thead.appendChild(theadTr);
  const tbody = document.createElement('tbody');
  const tbodyTr = document.createElement('tr');
  tbody.appendChild(tbodyTr);
  for (const [name, value] of Object.entries(data.attributes)) {
    const th = document.createElement('th');
    th.appendChild(document.createTextNode(name));
    theadTr.appendChild(th);
    const td = document.createElement('td');
    td.appendChild(document.createTextNode(value));
    tbodyTr.appendChild(td);
  }
  table.appendChild(thead);
  table.appendChild(tbody);
  boxBody.appendChild(table);

  const indicator = div.querySelector('.loading-indicator');
  if (indicator) {
    indicator.parentNode.removeChild(indicator);
  }
  div.appendChild(box);

  const metrics = {
    NumberOfMessagesSent: 'Sum',
    ApproximateNumberOfMessagesVisible: 'Sum',
    ApproximateNumberOfMessagesNotVisible: 'Sum',
    ApproximateAgeOfOldestMessage: 'Maximum',
  };
  const row = document.createElement('div');
  row.classList.add('row');
  boxBody.appendChild(row);
  for (const [metricName, statistic] of Object.entries(metrics)) {
    $.getJSON(`${metricsUrl}?queue_name=${data.queue_name}&metric_name=${metricName}&statistic=${statistic}`).done(data => {
      renderChart(row, data);
    }).fail(jqxhr => {
      const errorMessage = document.createElement('div');
      errorMessage.classList.add('alert');
      errorMessage.classList.add('alert-danger');
      errorMessage.appendChild(document.createTextNode(`Failed to load SQS metrics ${metricName}: ${jqxhr.status}: ${jqxhr.statusText}`));

      return div.appendChild(errorMessage);
    });
  }
};

const renderChart = function(row, data) {
  const div = document.createElement('div');
  div.classList.add('col-md-3');
  const chartDiv = document.createElement('div');
  div.appendChild(chartDiv);
  div.dataset.label = data.label;

  // Insert charts ordered by label name
  let inserted = false;
  for (const child of row.children) {
    if (data.label < child.dataset.label) {
      row.insertBefore(div, child);
      inserted = true;
      break;
    }
  }
  if (!inserted) {
    row.appendChild(div);
  }

  return Plotly.plot(chartDiv, [{
    type: 'scatter',
    x: data.datapoints.map(point => point.timestamp),
    y: data.datapoints.map(point => point.value),
  }], {
    title: data.label,
  });
};
