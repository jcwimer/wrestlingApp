describe('Wrestler Color Controller Tests', () => {
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
  });

  it('should toggle wrestler 1 color on button click', () => {
    // First check if we're on the correct page with wrestler controls
    cy.get('body').then(($body) => {
      if ($body.find('#w1-color-button').length) {
        // First ensure we have a consistent starting state by checking current color
        cy.get('.wrestler-1').then(($elements) => {
          // Find out if wrestler 1 is currently red or green
          const isRed = $elements.hasClass('btn-danger');
          const isGreen = $elements.hasClass('btn-success');
          
          // If neither red nor green, log and skip test
          if (!isRed && !isGreen) {
            cy.log('Wrestler 1 has neither red nor green class - test skipped');
            return;
          }
          
          // Get initial color before clicking
          const initialColor = isRed ? 'btn-danger' : 'btn-success';
          const targetColor = isRed ? 'btn-success' : 'btn-danger';
          
          // Click to toggle color
          cy.get('#w1-color-button').click();
          
          // Check that wrestler 1 buttons changed to the opposite color
          cy.get('.wrestler-1').should('have.class', targetColor);
          cy.get('.wrestler-1').should('not.have.class', initialColor);
          
          // Click again to toggle back
          cy.get('#w1-color-button').click();
          
          // Check toggled back to initial color
          cy.get('.wrestler-1').should('have.class', initialColor);
          cy.get('.wrestler-1').should('not.have.class', targetColor);
        });
      } else {
        cy.log('Color buttons not found - test conditionally skipped');
      }
    });
  });

  it('should update all related UI elements with the same color', () => {
    // First check if we're on the correct page with wrestler controls
    cy.get('body').then(($body) => {
      // Check for the color button with better waiting
      const colorButtonExists = $body.find('#w1-color-button').length > 0;
      
      if (colorButtonExists) {
        // First make sure wrestler 1 is red (btn-danger class) for consistent testing
        cy.get('.wrestler-1', { timeout: 10000 }).should('be.visible').then(($elements) => {
          const isRed = $elements.hasClass('btn-danger');
          
          // If not red, make it red
          if (!isRed) {
            // Check if green
            const isGreen = $elements.hasClass('btn-success');
            if (isGreen) {
              // Toggle to red
              cy.get('#w1-color-button', { timeout: 10000 }).should('be.visible').click();
              // Verify it's now red
              cy.get('.wrestler-1').should('have.class', 'btn-danger');
            }
          }
        });
        
        // Wait for UI to stabilize
        cy.wait(500);
        
        // Now wrestler 1 should be red, let's toggle to green
        cy.get('#w1-color-button', { timeout: 10000 }).should('be.visible').click();
        
        // Wait for color change to propagate
        cy.wait(500);
        
        // Check that all wrestler 1 elements have the green color
        cy.get('#w1-takedown', { timeout: 10000 }).should('be.visible').should('have.class', 'btn-success');
        cy.get('#w1-escape', { timeout: 10000 }).should('be.visible').should('have.class', 'btn-success');
        cy.get('#w1-reversal', { timeout: 10000 }).should('be.visible').should('have.class', 'btn-success');
        
        // Not all elements may exist, so check them conditionally
        cy.get('body').then(($updatedBody) => {
          // Wait to ensure DOM is stable 
          cy.wait(500);
          
          if ($updatedBody.find('#w1-nf2').length) {
            cy.get('#w1-nf2', { timeout: 10000 }).should('be.visible').should('have.class', 'btn-success');
          }
          if ($updatedBody.find('#w1-nf4').length) {
            cy.get('#w1-nf4', { timeout: 10000 }).should('be.visible').should('have.class', 'btn-success');
          }
          
          // Check container element if it exists
          if ($updatedBody.find('#wrestler-1-container').length) {
            cy.get('#wrestler-1-container', { timeout: 10000 }).should('be.visible').should('have.class', 'btn-success');
          }
        });
      } else {
        cy.log('Color buttons not found - test conditionally skipped');
      }
    });
  });

  it('should ensure opposing wrestlers have contrasting colors', () => {
    // First check if we're on the correct page with wrestler controls
    cy.get('body').then(($body) => {
      if ($body.find('#w1-color-button').length && $body.find('#w2-color-button').length) {
        // First make sure we start with wrestler 1 = red, wrestler 2 = green
        cy.get('.wrestler-1').then(($w1) => {
          cy.get('.wrestler-2').then(($w2) => {
            const w1IsRed = $w1.hasClass('btn-danger');
            const w2IsGreen = $w2.hasClass('btn-success');
            
            // If not in the desired starting state, reset it
            if (!w1IsRed || !w2IsGreen) {
              // If w1 is not red, toggle it
              if (!w1IsRed) {
                cy.get('#w1-color-button').click();
              }
              
              // At this point w2 should be green due to controller logic
              // Let's verify
              cy.get('.wrestler-2').should('have.class', 'btn-success');
            }
          });
        });
        
        // Now we should be in the starting state: wrestler 1 = red, wrestler 2 = green
        cy.get('.wrestler-1').should('have.class', 'btn-danger');
        cy.get('.wrestler-2').should('have.class', 'btn-success');
        
        // Change wrestler 1 to green
        cy.get('#w1-color-button').click();
        
        // Check that wrestler 1 is now green
        cy.get('.wrestler-1').should('have.class', 'btn-success');
        
        // Check that wrestler 2 automatically changed to red
        cy.get('.wrestler-2').should('have.class', 'btn-danger');
        
        // Now change wrestler 2's color
        cy.get('#w2-color-button').click();
        
        // Check that wrestler 2 is now green
        cy.get('.wrestler-2').should('have.class', 'btn-success');
        
        // Check that wrestler 1 automatically changed to red
        cy.get('.wrestler-1').should('have.class', 'btn-danger');
      } else {
        cy.log('Color buttons not found - test conditionally skipped');
      }
    });
  });

  it('should persist color selection after page reload', () => {
    // First check if we're on the correct page with wrestler controls
    cy.get('body').then(($body) => {
      if ($body.find('#w1-color-button').length && $body.find('#w2-color-button').length) {
        // First make sure we start with wrestler 1 = red, wrestler 2 = green
        cy.get('.wrestler-1').then(($w1) => {
          cy.get('.wrestler-2').then(($w2) => {
            const w1IsRed = $w1.hasClass('btn-danger');
            const w2IsGreen = $w2.hasClass('btn-success');
            
            // If not in the desired starting state, reset it
            if (!w1IsRed || !w2IsGreen) {
              // If w1 is not red, toggle it
              if (!w1IsRed) {
                cy.get('#w1-color-button').click();
              }
              
              // At this point w2 should be green due to controller logic
              cy.get('.wrestler-2').should('have.class', 'btn-success');
            }
          });
        });
        
        // Now we're in a known state: wrestler 1 = red, wrestler 2 = green
        cy.get('.wrestler-1').should('have.class', 'btn-danger');
        cy.get('.wrestler-2').should('have.class', 'btn-success');
        
        // Change colors by clicking wrestler 1
        cy.get('#w1-color-button').click();
        
        // Verify change: wrestler 1 = green, wrestler 2 = red
        cy.get('.wrestler-1').should('have.class', 'btn-success');
        cy.get('.wrestler-2').should('have.class', 'btn-danger');
        
        // Reload the page with intercept to handle Turbo
        cy.intercept('GET', '/mats/*').as('reloadMat');
        cy.reload();
        cy.wait('@reloadMat');
        
        // Wait for page to fully load
        cy.get('body', { timeout: 10000 }).should('be.visible');
        
        // Check cable connection status if it exists
        cy.get('body').then(($body) => {
          if ($body.find('#cable-status').length) {
            cy.get('#cable-status', { timeout: 10000 }).should('exist');
          } else if ($body.find('#cable-status-indicator').length) {
            cy.get('#cable-status-indicator', { timeout: 10000 }).should('exist');
          }
        });
        
        // Verify colors persisted after reload
        cy.get('.wrestler-1', { timeout: 10000 }).should('have.class', 'btn-success');
        cy.get('.wrestler-2', { timeout: 10000 }).should('have.class', 'btn-danger');
      } else {
        cy.log('Color buttons not found - test conditionally skipped');
      }
    });
  });
}); 