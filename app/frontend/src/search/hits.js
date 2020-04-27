export const renderHits = (renderOptions) => {
  const { results, widgetParams } = renderOptions;

  if (results) {
    widgetParams.container.innerHTML = `There are ${results.nbHits} jobs listed`;
  }
};

export const snakeCaseToHumanReadable = value => value.toLowerCase().replace(/_/g, ' ');

export const timestampToHumanReadable = timestamp => new Date(timestamp * 1000).toLocaleDateString('en-GB', { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: 'numeric' });

export const transform = items => items.map(item => ({
  ...item,
  working_patterns: item.working_patterns.map(snakeCaseToHumanReadable).join(', '),
  expiry_date: timestampToHumanReadable(item.expiry_date),
  school_type: snakeCaseToHumanReadable(item.school.phase)
}));

export const templates = {
  item: `
<article class="vacancy">
  <h2 class="govuk-heading-m mb0">
    <a href="{{ url }}" class="govuk-link view-vacancy-link">
    {{ job_title }}
    </a>
    </h2>
  <p>{{ school.name }}, {{ school.town }}, {{ school.region }}.</p>
  <dl>
<dt>Salary</dt>
<dd class="double">
&pound;{{ minValue }} to &pound;{{ maxValue }}
</dd>
<dt>School type</dt>
<dd class="double">
{{ school_type }}
</dd>
<dt>Working pattern</dt>
<dd class="double">
{{ working_patterns }}
</dd>
<dt>Closing date</dt>
<dd class="double">
{{ expiry_date }}
</dd>
</dl>
</article>
`};