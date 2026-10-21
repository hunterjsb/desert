'use strict';
const $ = id => document.getElementById(id);
const node = (tag, text, cls) => { const n = document.createElement(tag); if (text !== undefined) n.textContent = text; if (cls) n.className = cls; return n; };
const duration = n => n == null ? 'Unavailable' : n < 60 ? `${n.toFixed(0)} s` : `${(n / 60).toFixed(1)} min`;
const number = n => Number(n).toLocaleString(undefined, {maximumFractionDigits: 3});
const good = result => result === 'success' || result === 'PASS';
const link = (text, url) => { const a = node('a', text); const u = new URL(url); if (u.protocol === 'https:' && u.hostname === 'github.com') a.href = u.href; return a; };
let data;
let showAll = false;
function empty(id, message) { $(id).append(node('p', message, 'empty')); }
function card(title, value, detail) { const c = node('div', undefined, 'card'); c.append(node('small', title), node('strong', value), node('p', detail)); return c; }
function source(run, path) { return `https://github.com/${data.repository}/blob/${run.sha}/${path}`; }
function older(run) { return data.runs.filter(r => r.workflow === run.workflow && r.created_at < run.created_at); }
function priorProbe(run, row) {
  for (const previous of older(run)) for (const job of previous.jobs) {
    if (job.platform !== row.platform) continue;
    const p = job.probes.find(p => p.path === row.path && p.result === 'PASS');
    if (p) return p.seconds;
  }
  return null;
}
function priorMetric(run, metric) {
  for (const previous of older(run)) for (const job of previous.jobs) {
    if (job.platform !== metric.platform) continue;
    const sample = job.metrics.filter(m => m.probe === metric.probe && m.name === metric.name && m.unit === metric.unit && m.result === 'PASS').at(-1);
    if (sample) return {sample, run: previous};
  }
  return null;
}
function stat(label, value, scope) {
  const tr = node('tr'); tr.append(node('td', label), node('td', value), node('td', scope)); return tr;
}
function scatter(run) {
  const history = data.runs.filter(r => r.workflow === run.workflow && r.elapsed_seconds != null && Number.isFinite(Date.parse(r.created_at)));
  if (!history.length) { empty('history', 'No elapsed-time measurements available.'); return; }
  const svgNode = (tag, attrs, text) => {
    const n = document.createElementNS('http://www.w3.org/2000/svg', tag);
    for (const [key, value] of Object.entries(attrs)) n.setAttribute(key, value);
    if (text !== undefined) n.textContent = text;
    return n;
  };
  const width = Math.max(340, $('history').clientWidth), height = 290;
  const left = 58, right = width - 28, top = 28, bottom = height - 60;
  const times = history.map(r => Date.parse(r.created_at));
  let first = Math.min(...times), last = Math.max(...times);
  if (first === last) { first -= 1800000; last += 1800000; }
  const peak = Math.max(...history.map(r => r.elapsed_seconds / 60));
  const maxMinutes = Math.max(1, Math.ceil(peak * 1.1 / 20)) * 20;
  const x = time => left + (time - first) / (last - first) * (right - left);
  const y = seconds => bottom - seconds / 60 / maxMinutes * (bottom - top);
  const svg = svgNode('svg', {viewBox: `0 0 ${width} ${height}`, role: 'group', 'aria-label': `${run.workflow} runs: start time versus elapsed minutes`});
  svg.append(svgNode('text', {x: left, y: 14, class: 'axis-label'}, 'Elapsed minutes'));
  for (let i = 0; i <= 4; i++) {
    const value = maxMinutes * i / 4, yy = y(value * 60);
    svg.append(svgNode('line', {x1: left, x2: right, y1: yy, y2: yy, class: 'grid-line'}),
      svgNode('text', {x: left - 10, y: yy + 4, 'text-anchor': 'end', class: 'axis-label'}, number(value)));
  }
  const ticks = width < 600 ? 2 : 4;
  for (let i = 0; i <= ticks; i++) {
    const time = first + (last - first) * i / ticks, xx = x(time), date = new Date(time);
    const anchor = i === 0 ? 'start' : i === ticks ? 'end' : 'middle';
    svg.append(svgNode('text', {x: xx, y: bottom + 22, 'text-anchor': anchor, class: 'axis-label'}, date.toLocaleDateString(undefined, {month: 'short', day: 'numeric'})),
      svgNode('text', {x: xx, y: bottom + 39, 'text-anchor': anchor, class: 'axis-label'}, date.toLocaleTimeString(undefined, {hour: '2-digit', minute: '2-digit'})));
  }
  // Draw the selected run last so its ring remains visible among nearby samples.
  for (const r of history.slice().sort((a,b) => Number(a.id === run.id) - Number(b.id === run.id))) {
    const selected = r.id === run.id;
    const label = `${new Date(r.created_at).toLocaleString()} · ${duration(r.elapsed_seconds)} · ${r.result} · ${r.sha.slice(0,7)}`;
    const dot = svgNode('circle', {cx: x(Date.parse(r.created_at)), cy: y(r.elapsed_seconds), r: selected ? 7 : 5,
      class: `run-dot ${good(r.result) ? '' : 'failed'} ${selected ? 'selected' : ''}`, tabindex: 0, role: 'button',
      'aria-label': label, 'aria-pressed': selected, 'data-run': r.id});
    dot.append(svgNode('title', {}, label));
    const choose = () => {
      $('run').value = String(r.id); render();
      $('history').querySelector(`[data-run="${r.id}"]`).focus({preventScroll: true});
    };
    dot.addEventListener('click', choose);
    dot.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); choose(); } });
    svg.append(dot);
  }
  $('history').append(svg);
}
function render() {
  const run = data.runs.find(r => String(r.id) === $('run').value);
  if (!run) return;
  const os = $('platform').value, query = $('search').value.toLowerCase();
  const jobs = run.jobs.filter(j => os === 'All platforms' || j.platform === os);
  const rows = jobs.flatMap(j => j.probes.map(p => ({...p, platform:j.platform, url:j.html_url}))).filter(p => p.path.toLowerCase().includes(query));
  for (const id of ['run-info','summary','history','metrics','probes','jobs','artifacts']) $(id).replaceChildren();
  $('run-info').append(node('span', run.result, `badge ${good(run.result) ? '' : 'bad'}`), link(`${run.workflow} #${run.id} ↗`, run.url), node('span', `${run.sha.slice(0,8)} · ${run.branch} · attempt ${run.attempt}`));
  const execution = jobs.reduce((s,j) => s + (j.seconds || 0), 0);
  const allRows = jobs.flatMap(j => j.probes);
  const retried = allRows.filter(p => p.attempts.length > 1);
  $('summary').append(stat('Workflow elapsed', duration(run.elapsed_seconds), 'Whole run · includes waits / reruns'),
    stat('Longest selected job', duration(jobs.some(j=>j.seconds!=null) ? Math.max(...jobs.map(j=>j.seconds || 0)) : null), `${jobs.length} jobs · ${duration(execution)} summed execution`),
    stat('Probe verdicts', `${allRows.filter(p=>good(p.result)).length} / ${allRows.length}`, 'Final passing / observed · selected platform'),
    stat('Retry cost', duration(retried.reduce((s,p)=>s+p.retry_seconds,0)), `${retried.length} probes needed another attempt`));
  scatter(run);
  const metrics = jobs.flatMap(j=>j.metrics.map(m=>({...m,platform:j.platform,url:j.html_url}))).filter(m=>(m.probe+' '+m.name).toLowerCase().includes(query));
  // Show the last attempt of each measurement, retaining its result explicitly.
  const last = new Map(metrics.map(m=>[`${m.platform}:${m.probe}:${m.name}`,m]));
  for (const m of last.values()) {
    const tr = node('tr'), name = node('td');
    name.append(node('span', m.name), node('br'), link(m.probe.replace('probes/',''), source(run,m.probe)));
    const hasLimit = m.budget !== undefined;
    const status = !hasLimit ? 'No limit' : m.value > m.budget ? 'Above limit' : m.value === m.budget ? 'At limit' : 'Below limit';
    const verdict = node('td'); verdict.append(link(`${m.result} · attempt ${m.attempt}`, m.url));
    const reference = node('td'), previous = priorMetric(run,m);
    let change = '—';
    if (previous) {
      reference.append(link(`${number(previous.sample.value)} ${m.unit} · ${previous.run.sha.slice(0,7)}`, previous.run.url));
      const delta = m.value - previous.sample.value;
      change = `${delta > 0 ? '+' : ''}${number(delta)} ${m.unit}`;
      if (previous.sample.value > 0) change += ` (${delta > 0 ? '+' : ''}${number(delta / previous.sample.value * 100)}%)`;
    } else reference.textContent = 'No earlier sample';
    tr.append(name, node('td',m.platform), node('td',`${number(m.value)} ${m.unit}`),
      node('td',hasLimit ? `${number(m.budget)} ${m.unit}` : '—'),
      node('td',status,hasLimit && m.value > m.budget ? 'bad' : ''), verdict, reference, node('td',change));
    $('metrics').append(tr);
  }
  if(!last.size){const tr=node('tr'),td=node('td','No structured measurements for this selection. Older runs predate reporting; real-frame measurements run on Linux only.');td.colSpan=8;tr.append(td);$('metrics').append(tr);}
  for (const p of rows.sort((a,b)=>b.total_seconds-a.total_seconds).slice(0,showAll?rows.length:50)) {
    const tr=node('tr'), name=node('td');name.append(link(p.path.replace('probes/',''),source(run,p.path)));
    const result=node('td'); result.append(link(p.result + (p.attempts.length>1?` · ${p.attempts.length} attempts`:''),p.url));
    result.title=p.attempts.map(a=>`${a.result} ${duration(a.seconds)}`).join(' → ');
    const before=priorProbe(run,p); const change=before>0&&p.result==='PASS'?`${((p.seconds-before)/before*100)>=0?'+':''}${((p.seconds-before)/before*100).toFixed(0)}%`:'—';
    tr.append(name,node('td',p.platform),result,node('td',duration(p.total_seconds)),node('td',duration(p.retry_seconds)),node('td',change));$('probes').append(tr);
  }
  if(!rows.length){const tr=node('tr'),td=node('td','No probe verdicts match this selection.');td.colSpan=6;tr.append(td);$('probes').append(tr);}
  $('show-all').hidden=rows.length<=50;
  $('show-all').textContent=showAll?'Show the slowest 50':'Show all matching probes';
  const missing=jobs.filter(j=>j.log_status.startsWith('unavailable')||j.log_status==='no_verdicts');
  $('coverage').textContent=`${Math.min(rows.length,showAll?rows.length:50)} shown of ${rows.length} matching probes. ${missing.length ? 'Incomplete log coverage: '+missing.map(j=>j.name+' — '+j.log_status).join('; ') : 'All requested probe logs were available.'} Native runs omit real-frame timing probes by design.`;
  const maxJob=Math.max(1,...jobs.map(j=>j.seconds||0));
  for(const j of jobs.slice().sort((a,b)=>(b.seconds||0)-(a.seconds||0))){
    const d=node('details'),s=node('summary');s.append(node('span',j.conclusion||'unknown',`badge ${good(j.conclusion)?'':'bad'}`),node('span',j.name,'job-name'),node('span',duration(j.seconds),'job-time'));d.append(s);
    const meter=node('div',undefined,'meter');meter.style.width=`${(j.seconds||0)/maxJob*100}%`;d.append(meter);
    const ul=node('ul');for(const step of j.steps){const li=node('li');li.append(node('span',`${step.name} · ${step.result}`),node('span',duration(step.seconds)));ul.append(li);}
    d.append(ul,node('p',`Start offset: ${duration(j.start_offset_seconds)}`,'note'),link('Job evidence ↗',j.html_url));$('jobs').append(d);
  }
  const artifacts=run.artifacts.filter(a=>os==='All platforms'||a.name.includes({Linux:'linux',Windows:'windows',macOS:'macos'}[os]));
  for(const a of artifacts)$('artifacts').append(card(a.name,`${(a.bytes/1048576).toFixed(1)} MiB`,a.expired?'Artifact expired · recorded size':'Available from the source run'));
  if(!artifacts.length)empty('artifacts','No build artifact sizes were recorded for this selection.');
}
async function start(){
  try {
    const response=await fetch('./data.json');if(!response.ok)throw new Error(`HTTP ${response.status}`);data=await response.json();
    if(data.schema!==1||!Array.isArray(data.runs))throw new Error('Unsupported report schema');
    $('freshness').textContent=`Updated ${new Date(data.generated_at).toLocaleString()} · ${data.runs.length} retained runs · ${data.repository}`;
    for(const r of data.runs){const option=node('option',`${r.workflow} · ${new Date(r.created_at).toLocaleString()} · ${r.sha.slice(0,7)} · ${r.result}`);option.value=r.id;$('run').append(option);}
    $('show-all').onclick=()=>{showAll=!showAll;render();};
    for(const id of ['run','platform','search'])$(id).addEventListener(id==='search'?'input':'change',render);
    window.addEventListener('resize', () => { const run=data.runs.find(r=>String(r.id)===$('run').value); if(run){$('history').replaceChildren();scatter(run);} });
    if(data.runs.length)render();else $('freshness').textContent+=' · No completed runs available yet.';
  }catch(error){$('freshness').textContent=`Measurements could not be loaded: ${error.message}. Try refreshing or open GitHub Actions.`;}
}
start();
