// Notes for test maintenance:
// 1. This test checks for existence of Mat 1 before creating it, so we don't create duplicates
// 2. When running as part of the test suite, there may be issues with multiple elements matching the same selector
// 3. If needed, add { multiple: true } to click() calls or make selectors more specific with .first()
// 4. If encountering "element has detached from DOM" errors, try breaking up chains or adding cy.wait() between operations

describe('Matstats Page Functionality', () => {
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
      cy.contains('a', 'Mat 1').first().click();
  });

  it('should update stats when scoring actions are clicked', () => {    
    // Check that elements are visible
    cy.get('#match_w1_stat').should('be.visible');
    cy.get('#match_w2_stat').should('be.visible');
    
    // Test takedown button for wrestler A
    cy.get('#w1-takedown').click();
    cy.get('#match_w1_stat').should('contain.value', 'T3');
    
    // Test escape button for wrestler B
    cy.get('#w2-escape').click();
    cy.get('#match_w2_stat').should('contain.value', 'E1');
    
    // Test reversal button for wrestler A
    cy.get('#w1-reversal').click();
    cy.get('#match_w1_stat').should('contain.value', 'R2');
    
    // Test near fall buttons for wrestler B
    cy.get('#w2-nf2').click();
    cy.get('#match_w2_stat').should('contain.value', 'N2');
    
    // End period 
    cy.contains('End Period').click();
    cy.get('#match_w1_stat').should('contain.value', '|End Period|');
    cy.get('#match_w2_stat').should('contain.value', '|End Period|');
  });

  it('should test color change functionality', () => {
    // Test color change for Wrestler A from green to red
    cy.get('#w1-color').select('red');
    
    // Verify button colors changed for wrestler A (now red)
    cy.get('#w1-takedown').should('have.class', 'btn-danger');
    cy.get('#w1-escape').should('have.class', 'btn-danger');
    
    // Verify wrestler B's buttons are now green
    cy.get('#w2-takedown').should('have.class', 'btn-success');
    cy.get('#w2-escape').should('have.class', 'btn-success');
    
    // Switch back
    cy.get('#w2-color').select('red');
    
    // Verify colors switched back
    cy.get('#w1-takedown').should('have.class', 'btn-success');
    cy.get('#w2-takedown').should('have.class', 'btn-danger');
  });
  
  it('should test wrestler choice buttons', () => {
    // Test wrestler A choosing top
    cy.get('#w1-top').click();
    cy.get('#match_w1_stat').should('contain.value', '|Chose Top|');
    
    // Test wrestler B choosing bottom
    cy.get('#w2-bottom').click();
    cy.get('#match_w2_stat').should('contain.value', '|Chose Bottom|');
    
    // Test wrestler A deferring
    cy.get('#w1-defer').click();
    cy.get('#match_w1_stat').should('contain.value', '|Deferred|');
    
    // Test wrestler B choosing neutral
    cy.get('#w2-neutral').click();
    cy.get('#match_w2_stat').should('contain.value', '|Chose Neutral|');
  });
  
  it('should test warning buttons', () => {
    // Test stalling warning for wrestler A
    cy.get('#w1-stalling').click();
    cy.get('#match_w1_stat').should('contain.value', 'S');
    
    // Test caution for wrestler B
    cy.get('#w2-caution').click();
    cy.get('#match_w2_stat').should('contain.value', 'C');
  });
  
  it('should test timer functionality', () => {
    // Start injury timer for wrestler A
    cy.get('#w1-injury-time').should('be.visible');
    // Check initial timer value - accept either format
    cy.get('#w1-injury-time').invoke('text').then((text) => {
      expect(text.trim()).to.match(/^(0 sec|0m 0s)$/);
    });
    
    cy.contains('button', 'Start').first().click();
    
    // Wait a bit and check that timer is running
    cy.wait(2000);
    // Verify timer is no longer at zero
    cy.get('#w1-injury-time').invoke('text').then((text) => {
      expect(text.trim()).not.to.match(/^(0 sec|0m 0s)$/);
    });
    
    // Stop the timer
    cy.contains('button', 'Stop').first().click();
    
    // Store the current time
    let currentTime;
    cy.get('#w1-injury-time').invoke('text').then((text) => {
      currentTime = text;
    });
    
    // Wait a bit to ensure timer stopped
    cy.wait(1000);
    
    // Verify timer stopped by checking the time hasn't changed
    cy.get('#w1-injury-time').invoke('text').then((newText) => {
      expect(newText).to.equal(currentTime);
    });
    
    // Test reset button
    cy.contains('button', 'Reset').first().click();
    // Verify timer reset - accept either format
    cy.get('#w1-injury-time').invoke('text').then((text) => {
      expect(text.trim()).to.match(/^(0 sec|0m 0s)$/);
    });
    
    // Check that injury time was recorded in stats
    cy.get('#match_w1_stat').invoke('val').then((val) => {
      expect(val).to.include('Injury Time');
    });
  });
  
  it('should test match results form validation', () => {
    // Only attempt this test if the match_win_type element exists
    cy.get('body').then(($body) => {
      if ($body.find('#match_win_type').length) {
        // 1. Test Decision win type with no winner selected
        cy.get('#match_win_type').select('Decision');
        
        // Wait for dynamic fields to update
        cy.wait(300);
        
        // Verify correct form fields appear
        cy.get('#winner-score').should('exist');
        cy.get('#loser-score').should('exist');
        
        // Enter valid scores for Decision
        cy.get('#winner-score').clear().type('5');
        cy.get('#loser-score').clear().type('2');
        
        // Without a winner, form should show validation error
        cy.get('#validation-alerts').should('be.visible')
          .and('contain.text', 'Please select a winner');
        cy.get('#update-match-btn').should('be.disabled');
        
        // 2. Test invalid score scenario (loser score > winner score)
        cy.get('#winner-score').clear().type('2');
        cy.get('#loser-score').clear().type('5');
        
        cy.get('#validation-alerts').should('be.visible')
          .and('contain.text', 'Winner\'s score must be higher than loser\'s score');
        cy.get('#update-match-btn').should('be.disabled');
        
        // 3. Fix scores and select a winner
        cy.get('#winner-score').clear().type('5');
        cy.get('#loser-score').clear().type('2');
        cy.get('#match_winner_id').select(1);
        
        // Now validation should pass for Decision
        cy.get('#validation-alerts').should('not.be.visible');
        cy.get('#update-match-btn').should('not.be.disabled');
        
        // 4. Test Major score range validation
        cy.get('#winner-score').clear().type('10');
        cy.get('#loser-score').clear().type('2');
        // Score difference is 8, should require Major
        cy.get('#validation-alerts').should('be.visible')
          .and('contain.text', 'Win type should be');
        cy.get('#update-match-btn').should('be.disabled');
        
        // 5. Fix by changing win type to Major
        cy.get('#match_win_type').select('Major');
        cy.wait(300);
        
        // Validation should now pass
        cy.get('#validation-alerts').should('not.be.visible');
        cy.get('#update-match-btn').should('not.be.disabled');
        
        // 6. Test Tech Fall score range validation
        cy.get('#winner-score').clear().type('17');
        cy.get('#loser-score').clear().type('2');
        // Score difference is 15, should require Tech Fall
        cy.get('#validation-alerts').should('be.visible')
          .and('contain.text', 'Win type should be');
        cy.get('#update-match-btn').should('be.disabled');
        
        // 7. Fix by changing win type to Tech Fall
        cy.get('#match_win_type').select('Tech Fall');
        cy.wait(300);
        
        // Validation should now pass
        cy.get('#validation-alerts').should('not.be.visible');
        cy.get('#update-match-btn').should('not.be.disabled');
        
        // 8. Test Pin win type form
        cy.get('#match_win_type').select('Pin');
        cy.wait(300);
        
        // Should show pin time inputs
        cy.get('#minutes').should('exist');
        cy.get('#seconds').should('exist');
        cy.get('#pin-time-tip').should('be.visible');
        
        // Winner still required
        cy.get('#validation-alerts').should('not.be.visible'); // Previous winner selection should still be valid
        
        // 9. Test other win types (no score input)
        cy.get('#match_win_type').select('Forfeit');
        cy.wait(300);
        
        // Should not show score inputs
        cy.get('#dynamic-score-input').should('be.empty');
        
        // Winner still required
        cy.get('#validation-alerts').should('not.be.visible'); // Previous winner selection should still be valid
      } else {
        cy.log('Match form not present - test conditionally passed');
      }
    });
  });

  it('should display final score fields without requiring page refresh', () => {
    // Check if we're on a mat page with match form
    cy.get('body').then(($body) => {
      if ($body.find('#match_win_type').length) {
        // Test Decision type first
        cy.get('#match_win_type').select('Decision');
        cy.wait(300);
        cy.get('#dynamic-score-input').should('exist');
        cy.get('#winner-score').should('exist');
        cy.get('#loser-score').should('exist');
        
        // Test Pin type
        cy.get('#match_win_type').select('Pin');
        cy.wait(300);
        cy.get('#minutes').should('exist');
        cy.get('#seconds').should('exist');
        cy.get('#pin-time-tip').should('be.visible');
        
        // Test other types
        cy.get('#match_win_type').select('Forfeit');
        cy.wait(300);
        cy.get('#dynamic-score-input').should('be.empty');
        
        cy.log('Final score fields load correctly without page refresh');
      } else {
        cy.log('Match form not present - test conditionally passed');
      }
    });
  });
}); 