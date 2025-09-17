// Basic functionality tests for the counter app
const fs = require('fs');
const path = require('path');

console.log('🧪 Running functionality tests...\n');

// Test 1: Check if all required files exist
function testFilesExist() {
    const requiredFiles = ['index.html', 'style.css', 'script.js'];
    let allExist = true;
    
    requiredFiles.forEach(file => {
        if (fs.existsSync(file)) {
            console.log(`✅ ${file} exists`);
        } else {
            console.log(`❌ ${file} is missing`);
            allExist = false;
        }
    });
    
    return allExist;
}

// Test 2: Check HTML structure
function testHTMLStructure() {
    try {
        const html = fs.readFileSync('index.html', 'utf8');
        const requiredElements = [
            'counter-value',
            'increment-btn',
            'reset-btn'
        ];
        
        let allElementsFound = true;
        requiredElements.forEach(id => {
            if (html.includes(`id="${id}"`)) {
                console.log(`✅ Element #${id} found in HTML`);
            } else {
                console.log(`❌ Element #${id} missing from HTML`);
                allElementsFound = false;
            }
        });
        
        return allElementsFound;
    } catch (error) {
        console.log(`❌ Error reading HTML file: ${error.message}`);
        return false;
    }
}

// Test 3: Check CSS file content
function testCSSContent() {
    try {
        const css = fs.readFileSync('style.css', 'utf8');
        const requiredSelectors = [
            '.container',
            '.counter-display',
            '.btn'
        ];
        
        let allSelectorsFound = true;
        requiredSelectors.forEach(selector => {
            if (css.includes(selector)) {
                console.log(`✅ CSS selector ${selector} found`);
            } else {
                console.log(`❌ CSS selector ${selector} missing`);
                allSelectorsFound = false;
            }
        });
        
        return allSelectorsFound;
    } catch (error) {
        console.log(`❌ Error reading CSS file: ${error.message}`);
        return false;
    }
}

// Test 4: Check JavaScript functionality
function testJavaScriptContent() {
    try {
        const js = fs.readFileSync('script.js', 'utf8');
        const requiredFunctions = [
            'increment',
            'reset',
            'updateDisplay'
        ];
        
        let allFunctionsFound = true;
        requiredFunctions.forEach(func => {
            if (js.includes(func)) {
                console.log(`✅ JavaScript function/method ${func} found`);
            } else {
                console.log(`❌ JavaScript function/method ${func} missing`);
                allFunctionsFound = false;
            }
        });
        
        return allFunctionsFound;
    } catch (error) {
        console.log(`❌ Error reading JavaScript file: ${error.message}`);
        return false;
    }
}

// Run all tests
function runAllTests() {
    const tests = [
        { name: 'File Existence', test: testFilesExist },
        { name: 'HTML Structure', test: testHTMLStructure },
        { name: 'CSS Content', test: testCSSContent },
        { name: 'JavaScript Content', test: testJavaScriptContent }
    ];
    
    let allPassed = true;
    
    tests.forEach(({ name, test }) => {
        console.log(`\n--- ${name} Test ---`);
        const passed = test();
        if (!passed) {
            allPassed = false;
        }
    });
    
    console.log('\n' + '='.repeat(50));
    if (allPassed) {
        console.log('🎉 All functionality tests PASSED!');
        process.exit(0);
    } else {
        console.log('❌ Some functionality tests FAILED!');
        process.exit(1);
    }
}

runAllTests();