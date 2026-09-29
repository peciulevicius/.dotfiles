#!/usr/bin/env python3
"""Preview the 2026-09-29 rehire cleanup. Mutations require --apply.

--repair-routines remaps schedules to exact replacements, preserving status.
--retire terminates the 11 obsolete Coach/Studio records after reference checks.
The old Homelab Lead is excluded from this 11-record termination plan.
"""
import argparse
import http.cookiejar
import json
from pathlib import Path
import urllib.parse
import urllib.request

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--apply', action='store_true')
parser.add_argument('--repair-routines', action='store_true')
parser.add_argument('--retire', action='store_true')
args = parser.parse_args()
if args.apply and not (args.repair_routines or args.retire):
    parser.error('--apply requires --repair-routines or --retire')
incident_ids = {
    '12432817-656c-4c59-aa19-bdc57e4c6377', '895d2ed3-141a-4400-8b3b-0d42aea56b77',
    '91aa51ef-6082-4e36-9f27-3bd069837f09', '302c3396-9d7d-486c-a222-ce88681c9554',
    '84bfdfa1-eca5-4e50-ba1a-db3e43223a66', 'a5c3aa59-3045-4f76-b984-ef59b56bba52',
    'ad9a200b-cea6-4ec0-b5a1-6a0f56dd28fe', '06da5d90-9cbe-4fbb-b6cd-dae01422c17a',
    '262b7b28-8d45-4187-be5a-512c4e854fa8', '7ade1d2e-a346-4889-93af-c9756df55ed7',
    'f3fd798b-9a80-4f69-a8db-02b1ac9e0b1a',
}
base = 'http://127.0.0.1:3100'
credentials = {}
for line in (Path.home() / '.config/homelab/paperclip-admin.env').read_text().splitlines():
    if '=' in line and not line.startswith('#'):
        key, value = line.split('=', 1)
        credentials[key] = value.strip().strip('\"\'')
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
def api(method, path, body=None):
    request = urllib.request.Request(base + path, method=method,
        headers={'Origin': base, 'Content-Type': 'application/json'},
        data=json.dumps(body).encode() if body is not None else None)
    with opener.open(request, timeout=30) as response:
        return json.load(response)
def items(value):
    if isinstance(value, list):
        return value
    for key in ('items', 'routines', 'issues', 'data'):
        if isinstance(value, dict) and isinstance(value.get(key), list):
            return value[key]
    raise RuntimeError('Unexpected list shape')
def references(value, agent_id, path=''):
    if isinstance(value, dict):
        return [found for key, child in value.items()
                for found in references(child, agent_id, path + '.' + key)]
    if isinstance(value, list):
        return [found for i, child in enumerate(value)
                for found in references(child, agent_id, path + '.' + str(i))]
    return [path] if value == agent_id else []

api('POST', '/api/auth/sign-in/email', {'email': 'dziugas@peciulevicius.com',
    'password': credentials.pop('PAPERCLIP_ADMIN_PASSWORD')})
try:
    candidates = []
    seen_incident_ids = set()
    for company in api('GET', '/api/companies'):
        agents = items(api('GET', '/api/companies/' + company['id'] + '/agents'))
        for agent in agents:
            if agent['id'] in incident_ids:
                seen_incident_ids.add(agent['id'])
                if agent['status'] not in ('paused', 'terminated'):
                    raise RuntimeError('Incident record is no longer paused/terminated; refusing changed plan')
        routines = items(api('GET', '/api/companies/' + company['id'] + '/routines'))
        for routine in routines:
            old = next((a for a in agents if a['id'] == routine.get('assigneeAgentId')
                and 'retired' in a['name'].lower() and a['status'] == 'paused'), None)
            if old:
                replacements = [a for a in agents if a['name'] == old['name'].split(' (')[0]
                    and a['status'] in ('active','idle','running')]
                if len(replacements) != 1:
                    raise RuntimeError('Ambiguous routine replacement')
                print('Routine remap:', company['name'], routine['title'], 'to', replacements[0]['name'])
                if args.repair_routines and args.apply:
                    updated = api('PATCH', '/api/routines/' + routine['id'],
                        {'assigneeAgentId': replacements[0]['id']})
                    assert updated['status'] == routine['status'], 'Routine status changed unexpectedly'
                    routine.update(updated)
                    print('Routine remapped; status preserved:', updated['status'])
        for agent in agents:
            name = agent['name']
            if (agent['status'] != 'paused' or '2026-09-29' not in name
                    or not any(word in name.lower() for word in ('retired', 'duplicate hire'))):
                continue
            # Only the exact 11-record termination plan is authorized here.
            if agent['id'] not in incident_ids:
                continue
            replacement = [a for a in agents if a['name'] == name.split(' (')[0]
                and a['status'] in ('active', 'idle', 'running')]
            if len(replacement) != 1:
                raise RuntimeError('No unique replacement: ' + name)
            live_reports = [a['name'] for a in agents if a.get('reportsTo') == agent['id']
                and a['status'] != 'terminated' and not any(word in a['name'].lower() for word in ('retired', 'duplicate hire'))]
            query = urllib.parse.urlencode({'assigneeAgentId': agent['id']})
            issues = items(api('GET', '/api/companies/' + company['id'] + '/issues?' + query))
            open_issues = [i.get('identifier') for i in issues if i['status'] not in ('done','cancelled','canceled','rejected')]
            routine_refs = [(r.get('title') or r.get('name') or r['id'], references(r, agent['id']))
                for r in routines if references(r, agent['id'])]
            blocked = bool(live_reports or open_issues or routine_refs)
            print(json.dumps({'company': company['name'], 'name': name, 'id': agent['id'],
                'live_reports': live_reports, 'open_issues': open_issues, 'routine_refs': routine_refs,
                'ready': not blocked}))
            if not blocked:
                candidates.append(agent)
    print('Ready records:', len(candidates))
    bridge = (Path.home() / 'services/discord-bridge/.env').read_text()
    mapping = next((line for line in bridge.splitlines() if line.startswith('CHANNEL_MAP=')), '')
    if not mapping:
        raise RuntimeError('Missing bridge mapping; refusing unchecked external references')
    if any(agent['id'] in mapping for agent in candidates):
        raise RuntimeError('Discord bridge still references a retirement candidate')
    if args.apply and args.retire:
        if seen_incident_ids != incident_ids:
            raise RuntimeError('An incident record is missing; refusing unchecked plan')
        ready_ids = {agent['id'] for agent in candidates}
        # Earlier completed terminations are skipped on retry. A blocked paused
        # record is not silently skipped during an approved batch.
        paused_ids = set()
        for agent_id in incident_ids:
            if api('GET', '/api/agents/' + agent_id)['status'] == 'paused':
                paused_ids.add(agent_id)
        if ready_ids != paused_ids:
            raise RuntimeError('An incident record still has references; refusing partial cleanup')
        for agent in candidates:
            current = api('GET', '/api/agents/' + agent['id'])
            if current['status'] != 'paused' or current['name'] != agent['name']:
                raise RuntimeError('Agent changed after preflight; refusing termination')
            result = api('POST', '/api/agents/' + agent['id'] + '/terminate', {})
            if result.get('status') != 'terminated':
                raise RuntimeError('Termination not confirmed')
            print('Terminated:', agent['name'])
finally:
    api('POST', '/api/auth/sign-out', {})
