// Project structure validation tests
const fs = require('fs');

console.log('🏗️  Running project structure tests...\n');

// Test project structure
function testProjectStructure() {
    const expectedStructure = {
        'index.html': 'HTML file',
        'style.css': 'CSS file', 
        'script.js': 'JavaScript file',
        'package.json': 'Package configuration',
        'stop-hook-validator.sh': 'Stop hook script',
        '.claude/settings.json': 'Claude Code settings'
    };
    
    let allValid = true;
    
    Object.entries(expectedStructure).forEach(([file, description]) => {
        if (fs.existsSync(file)) {
            console.log(`✅ ${file} (${description})`);
        } else {
            console.log(`❌ ${file} (${description}) - MISSING`);
            allValid = false;
        }
    });
    
    return allValid;
}

// Test package.json content
function testPackageJSON() {
    try {
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        const requiredScripts = ['build', 'test', 'lint'];
        let allScriptsExist = true;
        
        console.log('\n--- Package.json Scripts ---');
        requiredScripts.forEach(script => {
            if (pkg.scripts && pkg.scripts[script]) {
                console.log(`✅ Script "${script}" defined`);
            } else {
                console.log(`❌ Script "${script}" missing`);
                allScriptsExist = false;
            }
        });
        
        return allScriptsExist;
    } catch (error) {
        console.log(`❌ Error reading package.json: ${error.message}`);
        return false;
    }
}

// Test HTML validation
function testHTMLValidity() {
    try {
        const html = fs.readFileSync('index.html', 'utf8');
        
        // Basic HTML structure checks
        const checks = [
            { test: html.includes('<!DOCTYPE html>'), name: 'DOCTYPE declaration' },
            { test: html.includes('<html'), name: 'HTML tag' },
            { test: html.includes('<head>'), name: 'Head section' },
            { test: html.includes('<body>'), name: 'Body section' },
            { test: html.includes('</html>'), name: 'Closing HTML tag' }
        ];
        
        console.log('\n--- HTML Structure Validation ---');
        let allValid = true;
        checks.forEach(({ test, name }) => {
            if (test) {
                console.log(`✅ ${name}`);
            } else {
                console.log(`❌ ${name} missing`);
                allValid = false;
            }
        });
        
        return allValid;
    } catch (error) {
        console.log(`❌ Error validating HTML: ${error.message}`);
        return false;
    }
}

// Run structure tests
function runStructureTests() {
    const tests = [
        { name: 'Project Structure', test: testProjectStructure },
        { name: 'Package Configuration', test: testPackageJSON },
        { name: 'HTML Validity', test: testHTMLValidity }
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
        console.log('🎉 All structure tests PASSED!');
        process.exit(0);
    } else {
        console.log('❌ Some structure tests FAILED!');
        process.exit(1);
    }
}

runStructureTests();