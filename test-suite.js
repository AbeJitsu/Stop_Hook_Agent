#!/usr/bin/env node

// Consolidated test suite for counter app
const fs = require('fs');
const path = require('path');

console.log('🧪 Running consolidated test suite...\n');

let testsPassed = 0;
let totalTests = 0;

// Test helper
function test(name, fn) {
    totalTests++;
    try {
        if (fn()) {
            console.log(`✅ ${name}`);
            testsPassed++;
        } else {
            console.log(`❌ ${name}`);
        }
    } catch (error) {
        console.log(`❌ ${name}: ${error.message}`);
    }
}

// Structure Tests
console.log('📁 Structure Tests:');
test('Counter app files exist', () => {
    const required = ['counter-app/index.html', 'counter-app/style.css', 'counter-app/script.js'];
    return required.every(file => fs.existsSync(file));
});


// Syntax Tests
console.log('\n🔧 Syntax Tests:');
test('JavaScript files have valid syntax', () => {
    const jsFiles = [
        'counter-app/script.js',
        'test-suite.js'
    ];
    
    for (const file of jsFiles) {
        if (fs.existsSync(file)) {
            try {
                require('child_process').execSync(`node -c "${file}"`, { stdio: 'pipe' });
            } catch (e) {
                return false;
            }
        }
    }
    return true;
});

test('JSON files are valid', () => {
    const jsonFiles = fs.readdirSync('.').filter(f => f.endsWith('.json'));
    for (const file of jsonFiles) {
        try {
            JSON.parse(fs.readFileSync(file, 'utf8'));
        } catch (e) {
            return false;
        }
    }
    return true;
});

// HTML Structure Tests
console.log('\n🌐 HTML Tests:');
test('HTML has required counter elements', () => {
    if (!fs.existsSync('counter-app/index.html')) return false;
    const html = fs.readFileSync('counter-app/index.html', 'utf8');
    const required = ['counter-value', 'increment-btn', 'reset-btn'];
    return required.every(id => html.includes(`id="${id}"`));
});

test('HTML links to CSS and JS files', () => {
    if (!fs.existsSync('counter-app/index.html')) return false;
    const html = fs.readFileSync('counter-app/index.html', 'utf8');
    return html.includes('style.css') && html.includes('script.js');
});

// CSS Tests
console.log('\n🎨 CSS Tests:');
test('CSS file is not empty', () => {
    if (!fs.existsSync('counter-app/style.css')) return false;
    const css = fs.readFileSync('counter-app/style.css', 'utf8');
    return css.trim().length > 10;
});

test('CSS has counter styling', () => {
    if (!fs.existsSync('counter-app/style.css')) return false;
    const css = fs.readFileSync('counter-app/style.css', 'utf8');
    return css.includes('counter') || css.includes('#counter-value');
});

// JavaScript Functionality Tests
console.log('\n⚙️ JavaScript Tests:');
test('JS implements increment function', () => {
    if (!fs.existsSync('counter-app/script.js')) return false;
    const js = fs.readFileSync('counter-app/script.js', 'utf8');
    return js.includes('increment') && (js.includes('++') || js.includes('+ 1'));
});

test('JS implements reset function', () => {
    if (!fs.existsSync('counter-app/script.js')) return false;
    const js = fs.readFileSync('counter-app/script.js', 'utf8');
    return js.includes('reset') && js.includes('= 0');
});

test('JS has event listeners', () => {
    if (!fs.existsSync('counter-app/script.js')) return false;
    const js = fs.readFileSync('counter-app/script.js', 'utf8');
    return js.includes('addEventListener') || js.includes('onclick');
});


// Summary
console.log('\n' + '='.repeat(50));
console.log(`Test Summary: ${testsPassed}/${totalTests} passed`);
console.log('='.repeat(50));

// Exit with appropriate code
process.exit(testsPassed === totalTests ? 0 : 1);