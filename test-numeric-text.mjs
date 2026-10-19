import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url),numeric=require('../word-web/numeric-text.js');
const cases=JSON.parse(fs.readFileSync(new URL('../tests/numeric-cases.json',import.meta.url),'utf8'));
const signatures=JSON.parse(fs.readFileSync(new URL('../artifacts/numeric-signatures.json',import.meta.url),'utf8'));
assert.equal(cases.length,signatures.length);
for(let i=0;i<cases.length;i++){assert.deepEqual(numeric.values(cases[i].source),signatures[i].source,'source parity '+i);assert.deepEqual(numeric.values(cases[i].result),signatures[i].result,'result parity '+i);}
const report=`PASS: browser and C# numeric signatures agree on ${cases.length} shared fixtures (${cases.length*2} text comparisons).`;
fs.writeFileSync(new URL('../artifacts/numeric-parity-test.txt',import.meta.url),report);console.log(report);
