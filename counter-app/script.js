// Counter App JavaScript
// Learning project for stop hook validation

class Counter {
    constructor() {
        this.value = 0;
        this.init();
    }

    init() {
        // Get DOM elements
        this.counterDisplay = document.getElementById('counter-value');
        this.incrementBtn = document.getElementById('increment-btn');
        this.resetBtn = document.getElementById('reset-btn');

        // Bind event listeners
        this.incrementBtn.addEventListener('click', () => this.increment());
        this.resetBtn.addEventListener('click', () => this.reset());

        // Initialize display
        this.updateDisplay();
        
        console.log('Counter app initialized successfully');
    }

    increment() {
        this.value++;
        this.updateDisplay();
        this.addClickEffect(this.incrementBtn);
        console.log(`Counter incremented to: ${this.value}`);
    }

    reset() {
        this.value = 0;
        this.updateDisplay();
        this.addClickEffect(this.resetBtn);
        console.log('Counter reset to 0');
    }

    updateDisplay() {
        if (this.counterDisplay) {
            this.counterDisplay.textContent = this.value;
            
            // Add animation effect
            this.counterDisplay.style.transform = 'scale(1.1)';
            setTimeout(() => {
                this.counterDisplay.style.transform = 'scale(1)';
            }, 150);
        }
    }

    addClickEffect(button) {
        button.style.transform = 'scale(0.95)';
        setTimeout(() => {
            button.style.transform = 'scale(1)';
        }, 100);
    }

    // Method to get current value (useful for testing)
    getValue() {
        return this.value;
    }

    // Method to set value (useful for testing)
    setValue(newValue) {
        if (typeof newValue === 'number' && newValue >= 0) {
            this.value = newValue;
            this.updateDisplay();
            return true;
        }
        return false;
    }
}

// Initialize the counter when the DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Create global counter instance for easy testing
    window.counter = new Counter();
    
    // Add some validation to ensure everything loaded correctly
    const requiredElements = [
        'counter-value',
        'increment-btn', 
        'reset-btn'
    ];
    
    const missingElements = requiredElements.filter(id => !document.getElementById(id));
    
    if (missingElements.length > 0) {
        console.error('Missing required elements:', missingElements);
    } else {
        console.log('✅ All required DOM elements found');
        console.log('✅ Counter app ready for use');
    }
});

// Export for potential testing (if using modules)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Counter;
}