const test = require('node:test');
const assert = require('node:assert');
const { add, subtract, multiply } = require('../src/calc');

test('add 2 + 3 = 5', () => assert.strictEqual(add(2, 3), 5));
test('subtract 5 - 2 = 3', () => assert.strictEqual(subtract(5, 2), 3));
test('multiply 4 * 3 = 12', () => assert.strictEqual(multiply(4, 3), 12));
