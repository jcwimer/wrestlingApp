Cypress.Commands.add('login', () => {
    cy.visit('/');
  
    cy.contains('Log In').click();
    cy.url().should('include', '/login');
  
    // Fill in login form and submit
    cy.get('input[type=email]').type(Cypress.env('CYPRESS_USERNAME'));
    cy.get('input[type=password]').type(Cypress.env('CYPRESS_PASSWORD'));
    cy.get('input[type=submit]').click();
  
    // Verify successful login
    cy.contains('Logged in successfully');
  });
  