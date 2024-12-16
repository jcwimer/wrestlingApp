describe('Create a tournament', () => {
  beforeEach(() => {
    // Use cy.session() with the login helper
    cy.session('authUser', () => {
      // cy.login() comes from cypress/support/commands.js
      cy.login();
    });
  });

  it('Browses Tournaments and Creates a New Pool to bracket Tournament', () => {
    // Navigate to the Browse Tournaments page
    cy.visit('/');
    cy.contains('Browse Tournaments').click();

    // Verify we're on the tournaments page
    cy.url().should('include', '/tournaments');
    cy.contains('Upcoming Tournaments');

    // Click "New Tournament"
    cy.get('a[href="/tournaments/new"]').click();

    // Verify we're on the "New Tournament" page
    cy.url().should('include', '/tournaments/new');

    // Fill out the tournament creation form
    cy.get('input[name="tournament[name]"]').type('Cypress Test Tournament - Pool to bracket');
    cy.get('input[name="tournament[address]"]').type('123 Wrestling Way');
    cy.get('input[name="tournament[director]"]').type('John Doe');
    cy.get('input[name="tournament[director_email]"]').type('john.doe@example.com');
    cy.get('input[name="tournament[date]"]').type('2024-12-31');
    cy.get('select[name="tournament[tournament_type]"]').select('Pool to bracket');
    // cy.get('input[name="tournament[is_public]"]').check();

    // Submit the form
    cy.contains('Submit').click();

    // Verify successful creation (adjust based on app behavior)
    cy.url().should('include', '/tournaments');
    cy.contains('Cypress Test Tournament - Pool to bracket');
    cy.contains('Tournament was successfully created.')
  });
});
