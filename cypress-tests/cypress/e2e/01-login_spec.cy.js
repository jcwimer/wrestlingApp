describe('Testing Log In', () => {
  it('Gets Log In Page and Logs In', () => {
    cy.visit('/')

    cy.contains('Log In').click()

    // Should be on a new URL which
    // includes '/commands/actions'
    cy.url().should('include', '/users/sign_in')

    // Get an input, type into it
    cy.get('[id=user_email]').type(Cypress.env('CYPRESS_USERNAME'))

    //  Verify that the value has been updated
    cy.get('[id=user_email]').should('have.value', Cypress.env('CYPRESS_USERNAME'))
    
    // Get an input, type into it
    cy.get('[id=user_password]').type(Cypress.env('CYPRESS_PASSWORD'))

    //  Verify that the value has been updated
    cy.get('[id=user_password]').should('have.value', Cypress.env('CYPRESS_PASSWORD'))
    
    cy.get('input[type=submit]').click()
    
    cy.contains('Signed in successfully')
  })
})