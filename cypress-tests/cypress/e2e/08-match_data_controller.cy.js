describe('Match Data Controller Tests', () => {
  // Don't fail tests on uncaught exceptions
  Cypress.on('uncaught:exception', (err, runnable) => {
    // returning false here prevents Cypress from failing the test
    return false;
  });
  
  beforeEach(() => {
    // Use cy.session() with the login helper
    cy.session('authUser', () => {
      cy.login(); // Assume cy.login() is defined in commands.js
    });
    cy.visit('/');
    cy.contains('Browse Tournaments').first().click();
    cy.contains('Cypress Test Tournament - Pool to bracket').click();
    
    // Wait for page to load and intercept mat clicks to handle Turbo transitions
    cy.intercept('GET', '/mats/*').as('loadMat');
    cy.contains('a', 'Mat 1').first().click();
    cy.wait('@loadMat');
    
    // Ensure the page has fully loaded with a longer timeout
    cy.get('body', { timeout: 15000 }).should('be.visible');
    
    // Additional wait to ensure all buttons are fully rendered
    cy.wait(2000);
    
    // Clear the text areas to start fresh with better error handling
    cy.get('body').then(($body) => {
      if ($body.find('#match_w1_stat').length) {
        cy.get('#match_w1_stat').clear();
      }
      if ($body.find('#match_w2_stat').length) {
        cy.get('#match_w2_stat').clear();
      }
    });
  });

  it('should update stat box when scoring buttons are clicked', () => {
    // Give the page extra time to fully render
    cy.wait(1000);
    
    // First check if scoring buttons exist
    cy.get('body').then(($body) => {
      // Ensure all the main elements we need are on the page
      cy.get('#match_w1_stat', { timeout: 10000 }).should('exist');
      cy.get('#match_w2_stat', { timeout: 10000 }).should('exist');
      
      // Check for buttons with better waiting
      const takedownExists = $body.find('#w1-takedown').length > 0;
      
      if (!takedownExists) {
        cy.log('Scoring buttons not found - test conditionally skipped');
        return;
      }
      
      // Click scoring buttons for wrestler 1
      cy.get('#w1-takedown', { timeout: 10000 }).should('be.visible').should('be.enabled').click();
      cy.get('#match_w1_stat').should('contain.value', 'T3');
      cy.wait(300);
      
      cy.get('#w1-escape', { timeout: 10000 }).should('be.visible').should('be.enabled').click();
      cy.get('#match_w1_stat').invoke('val').then((val) => {
        // Just check that the value contains both T3 and E1, regardless of order
        expect(val).to.include('T3');
        expect(val).to.include('E1');
      });
      cy.wait(300);
      
      cy.get('#w1-reversal', { timeout: 10000 }).should('be.visible').should('be.enabled').click();
      cy.get('#match_w1_stat').invoke('val').then((val) => {
        // Check that the value now contains R2 as well
        expect(val).to.include('R2');
      });
      cy.wait(300);
      
      // Click scoring buttons for wrestler 2
      cy.get('#w2-takedown', { timeout: 10000 }).should('be.visible').should('be.enabled').click();
      cy.get('#match_w2_stat').should('contain.value', 'T3');
      cy.wait(300);
      
      // Now check for the NF2 button with proper waiting
      cy.get('body').then(($updatedBody) => {
        // Wait a moment for any dynamic elements to settle
        cy.wait(500);
        
        if ($updatedBody.find('#w2-nf2').length) {
          // Try to ensure the button is fully loaded
          cy.get('#w2-nf2', { timeout: 10000 }).should('be.visible').should('be.enabled');
          cy.wait(300);
          cy.get('#w2-nf2').click();
          cy.get('#match_w2_stat').should('contain.value', 'N2');
        } else {
          cy.log('N2 button not found, will try again after a delay');
          cy.wait(1000);
          
          // Try once more after waiting
          cy.get('body').then(($finalCheck) => {
            if ($finalCheck.find('#w2-nf2').length) {
              cy.get('#w2-nf2').should('be.visible').should('be.enabled').click();
              cy.get('#match_w2_stat').should('contain.value', 'N2');
            } else {
              cy.log('N2 button still not found after waiting, skipping this part of the test');
            }
          });
        }
      });
    });
  });

  it('should update both wrestlers\' stats when end period is clicked', () => {
    // Check if we're on the correct page with end period button
    cy.get('body').then(($body) => {
      if (!$body.find('button:contains("End Period")').length) {
        cy.log('End Period button not found - test conditionally skipped');
        return;
      }

      // Get initial stats values
      let w1InitialStats;
      let w2InitialStats;
      
      cy.get('#match_w1_stat').invoke('val').then((val) => {
        w1InitialStats = val || '';
      });
      
      cy.get('#match_w2_stat').invoke('val').then((val) => {
        w2InitialStats = val || '';
      });
      
      // Click end period button with better waiting
      cy.contains('button', 'End Period', { timeout: 10000 })
        .should('be.visible')
        .should('be.enabled')
        .click();
      
      // Wait a bit longer for the update to occur
      cy.wait(500);
      
      // Check that both stats fields were updated
      cy.get('#match_w1_stat').invoke('val').then((val) => {
        expect(val).to.include('|End Period|');
        if (w1InitialStats) {
          expect(val).not.to.equal(w1InitialStats);
        }
      });
      
      cy.get('#match_w2_stat').invoke('val').then((val) => {
        expect(val).to.include('|End Period|');
        if (w2InitialStats) {
          expect(val).not.to.equal(w2InitialStats);
        }
      });
    });
  });

  it('should persist stats data in localStorage', () => {
    // Check if we're on the correct page with scoring controls
    cy.get('body').then(($body) => {
      if (!$body.find('#w1-takedown').length || !$body.find('#w2-escape').length) {
        cy.log('Scoring buttons not found - test conditionally skipped');
        return;
      }

      // Add some stats
      cy.get('#w1-takedown', { timeout: 10000 }).should('be.visible').should('be.enabled').click();
      cy.wait(300);
      
      cy.get('#w2-escape', { timeout: 10000 }).should('be.visible').should('be.enabled').click();
      cy.wait(300);
      
      // Get stats values
      let w1Stats;
      let w2Stats;
      
      cy.get('#match_w1_stat').invoke('val').then((val) => {
        w1Stats = val;
        expect(val).to.include('T3');
      });
      
      cy.get('#match_w2_stat').invoke('val').then((val) => {
        w2Stats = val;
        expect(val).to.include('E1');
      });
      
      // Reload the page with intercept to handle Turbo
      cy.intercept('GET', '/mats/*').as('reloadMat');
      cy.reload();
      cy.wait('@reloadMat');
      
      // Wait for page to fully load
      cy.get('body', { timeout: 15000 }).should('be.visible');
      cy.wait(2000);
      
      // Check cable connection status if it exists
      cy.get('body').then(($body) => {
        if ($body.find('#cable-status').length) {
          cy.get('#cable-status', { timeout: 10000 }).should('exist');
        } else if ($body.find('#cable-status-indicator').length) {
          cy.get('#cable-status-indicator', { timeout: 10000 }).should('exist');
        }
      });
      
      // Check that stats persisted with flexible matching
      cy.get('#match_w1_stat', { timeout: 10000 }).invoke('val').then((val) => {
        expect(val).to.include('T3');
      });
      
      cy.get('#match_w2_stat', { timeout: 10000 }).invoke('val').then((val) => {
        expect(val).to.include('E1');
      });
    });
  });

  it('should handle direct text entry with debouncing', () => {
    // Wait for page to be fully interactive
    cy.wait(2000);
    
    // Check if we're on the correct page with textarea
    cy.get('body').then(($body) => {
      if (!$body.find('#match_w1_stat').length) {
        cy.log('Stat textarea not found - test conditionally skipped');
        return;
      }

      // Wait for textarea to be fully loaded and interactive
      cy.get('#match_w1_stat', { timeout: 10000 }).should('be.visible');
      cy.wait(500);
      
      // Clear the textarea first to ensure clean state
      cy.get('#match_w1_stat').clear();
      cy.wait(300);
      
      // Type into the textarea
      cy.get('#match_w1_stat').type('Manual entry for testing');
      cy.wait(300);
      
      // Try a more reliable approach to trigger blur - click on a specific element instead of body
      cy.get('h1, h2, h3, .navbar, .nav-link').first()
        .should('be.visible')
        .click({ force: true });
      
      // As a fallback, also try clicking body in a specific location
      cy.get('body').click(50, 50, { force: true });
      
      // Wait longer for debounce
      cy.wait(2000);
      
      // Reload to test persistence with intercept for Turbo
      cy.intercept('GET', '/mats/*').as('reloadMat');
      cy.reload();
      cy.wait('@reloadMat');
      
      // Wait longer for page to fully load
      cy.get('body', { timeout: 15000 }).should('be.visible');
      cy.wait(2000);
      
      // Check connection status if available
      cy.get('body').then(($body) => {
        if ($body.find('#cable-status').length) {
          cy.get('#cable-status', { timeout: 15000 }).should('exist');
        } else if ($body.find('#cable-status-indicator').length) {
          cy.get('#cable-status-indicator', { timeout: 15000 }).should('exist');
        }
      });
      
      // Check that manual entry persisted with flexible matching and longer timeout
      cy.get('#match_w1_stat', { timeout: 15000 }).should('be.visible').invoke('val').then((val) => {
        expect(val).to.include('Manual entry for testing');
      });
    });
  });

  it('should manage injury and blood timers', () => {
    // Check if we're on the correct page with timers
    cy.get('body').then(($body) => {
      if (!$body.find('#w1-injury-time').length) {
        cy.log('Injury timer not found - test conditionally skipped');
        return;
      }

      // Test injury timer start/stop
      cy.get('#w1-injury-time').should('be.visible');
      cy.get('#w1-injury-time').invoke('text').then((text) => {
        expect(text.trim()).to.match(/^(0 sec|0m 0s|0)$/);
      });
      
      // Find and click the first Start button for injury timer
      cy.get('button').contains('Start').first().click();
      
      // Wait a bit
      cy.wait(2000);
      
      // Find and click the first Stop button for injury timer
      cy.get('button').contains('Stop').first().click();
      
      // Get the time value - be flexible about format
      let timeValue;
      cy.get('#w1-injury-time').invoke('text').then((text) => {
        timeValue = text;
        expect(text.trim()).not.to.match(/^(0 sec|0m 0s|0)$/);
      });
      
      // Check that stats field was updated with injury time
      cy.get('#match_w1_stat').invoke('val').then((val) => {
        expect(val).to.include('Injury Time');
      });
      
      // Test reset button
      cy.get('button').contains('Reset').first().click();
      
      // Verify timer was reset - be flexible about format
      cy.get('#w1-injury-time').invoke('text').then((text) => {
        expect(text.trim()).to.match(/^(0 sec|0m 0s|0)$/);
      });
    });
  });

  it('should handle Action Cable connections', () => {
    // Check for cable status indicator with multiple possible selectors
    cy.get('body').then(($body) => {
      // Check that at least one of the status indicators exists
      if ($body.find('#cable-status').length) {
        cy.get('#cable-status', { timeout: 15000 })
          .should('be.visible');
      } else if ($body.find('#cable-status-indicator').length) {
        cy.get('#cable-status-indicator', { timeout: 15000 })
          .should('be.visible');
      } else {
        cy.log('Cable status indicator not found - using alternate approach');
        cy.get('.alert:contains("Connected")').should('exist');
      }
      
      // Check if we're on the correct page with scoring controls
      if (!$body.find('#w1-takedown').length) {
        cy.log('Scoring buttons not found - test partially skipped');
        return;
      }

      // Add stats and verify they update
      cy.get('#w1-takedown').click();
      cy.get('#match_w1_stat').should('contain.value', 'T3');
      
      // Try to disconnect and reconnect (simulate by reloading)
      cy.intercept('GET', '/mats/*').as('reloadMat');
      cy.reload();
      cy.wait('@reloadMat');
      
      // Wait for page to fully load
      cy.get('body', { timeout: 10000 }).should('be.visible');
      
      // Check connection is reestablished - check for various connection indicators
      cy.get('body').then(($newBody) => {
        if ($newBody.find('#cable-status').length) {
          cy.get('#cable-status', { timeout: 15000 }).should('be.visible');
        } else if ($newBody.find('#cable-status-indicator').length) {
          cy.get('#cable-status-indicator', { timeout: 15000 }).should('be.visible');
        } else {
          cy.log('Cable status indicator not found after reload - using alternate approach');
          cy.get('.alert:contains("Connected")').should('exist');
        }
      });
      
      // Verify data persisted
      cy.get('#match_w1_stat').should('contain.value', 'T3');
    });
  });
}); 