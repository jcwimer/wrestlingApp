Cypress.Commands.add('login', () => {
    cy.visit('/');
  
    cy.contains('Log In').click();
    cy.url().should('include', '/users/sign_in');
  
    // Fill in login form and submit
    cy.get('[id=user_email]').type(Cypress.env('CYPRESS_USERNAME'));
    cy.get('[id=user_password]').type(Cypress.env('CYPRESS_PASSWORD'));
    cy.get('input[type=submit]').click();
  
    // Verify successful login
    cy.contains('Signed in successfully');
  });
  