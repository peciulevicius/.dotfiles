// Parse both bindings before comparing so object insertion order does not
// trigger an unnecessary provider probe on a reportsTo-only update. Changed
// bindings still go through the existing compatibility and login validation.
import { readFileSync, writeFileSync } from 'node:fs';

const files = ['/app/server/src/routes/agents.ts', '/app/server/dist/routes/agents.js'];
const before = 'const changed = JSON.stringify(nextAiBinding) !== JSON.stringify(existing.runtimeConfig.aiConnection);';
const after = 'const previousAiBinding = aiConnectionBindingSchema.safeParse(existing.runtimeConfig.aiConnection).data;\n'
  + '      const changed = JSON.stringify(nextAiBinding) !== JSON.stringify(previousAiBinding);';
const edits = files.map(path => {
  const source = readFileSync(path, 'utf8');
  if (source.split(before).length !== 2) {
    throw new Error(`Expected one pinned comparison in ${path}; refusing unknown server version`);
  }
  return [path, source.replace(before, after)];
});
for (const [path, source] of edits) writeFileSync(path, source);
console.log('Normalized AI binding comparison in the source and runtime bundle.');
