describe('Testing Log In', () => {
  it('Gets Log In Page and Logs In', () => {
    cy.visit('/')

    cy.contains('Log In').click()

    // Should be on the login URL
    cy.url().should('include', '/login')

    // Get an input, type into it
    cy.get('input[type=email]').type(Cypress.env('CYPRESS_USERNAME'))

    //  Verify that the value has been updated
    cy.get('input[type=email]').should('have.value', Cypress.env('CYPRESS_USERNAME'))
    
    // Get an input, type into it
    cy.get('input[type=password]').type(Cypress.env('CYPRESS_PASSWORD'))

    //  Verify that the value has been updated
    cy.get('input[type=password]').should('have.value', Cypress.env('CYPRESS_PASSWORD'))
    
    cy.get('input[type=submit]').click()
    
    // Check for successful login message
    cy.contains('Logged in successfully')
    
    // Verify we can see user email in navbar after login
    cy.get('.navbar').contains(Cypress.env('CYPRESS_USERNAME'))
  })
})