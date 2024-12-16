describe('Pool to bracket setup', () => {
  beforeEach(() => {
    // Use cy.session() with the login helper
    cy.session('authUser', () => {
      cy.login(); // Assume cy.login() is defined in commands.js
    });
    cy.visit('/');
    cy.contains('Browse Tournaments').click();
    cy.contains('Cypress Test Tournament - Pool to bracket').click();
  });

  it('Setup Pool to bracket tournament. 3 schools, hs boys weights, and wrestlers.', () => {
    // Create he boys weights
    // Listen for the confirmation popup and automatically confirm it
    cy.on('window:confirm', (text) => {
      // Assert the text in the popup, if needed
      expect(text).to.equal('Are you sure? This will delete all current weights.');
      return true; // Simulates clicking "OK"
    });

    // Click the link to trigger the confirmation popup
    cy.contains('Tournament Director Links').click();
    cy.contains('Create Boys High School Weights (106-285)').click();

    // Add assertions to verify the action
    cy.url().should('include', '/tournaments/');
    cy.contains('106.0');

    // 16 schools
    const schoolNames = Array.from({ length: 3 }, (_, i) => `School ${i + 1}`);
    const weights = ['106.0', '113.0', '120.0', '126.0', '132.0', '138.0', '144.0', '150.0', '157.0', '165.0', '175.0', '190.0', '215.0', '285.0'];
    let wrestlerCounter = 1;
  
    schoolNames.forEach((schoolName) => {
      // Click "New School"
      cy.get('a[href^="/schools/new"]').click(); // Matches links starting with /schools/new
      // Verify we're on the "New School" page
      cy.url().should('include', '/schools/new');
      // Fill out the school creation form
      cy.get('input[name="school[name]"]').type(schoolName);
      // Submit the form
      cy.contains('Submit').click();
      // Verify the school was created (adjust based on your app behavior)
      cy.url().should('include', '/tournaments');
      cy.contains('School was successfully created.');
    });
    cy.contains(`School 1`).click();
      
    // Create wrestlers for this school
    weights.forEach((weight) => {
      cy.get('a[href^="/wrestlers/new"]').click();
      // Fill out the wrestler form
      cy.get('input[name="wrestler[name]"]').type(`Wrestler${wrestlerCounter}`);

      // Select the weight class that matches the string variable
      cy.get('select[name="wrestler[weight_id]"]').select(weight);

      // Fill out the rest of the form
      cy.get('input[name="wrestler[season_win]"]').type('0');
      cy.get('input[name="wrestler[season_loss]"]').type('0');
      cy.get('input[name="wrestler[criteria]"]').type('N/A');
      // cy.get('input[name="wrestler[extra]"]').check();

      // Submit the form
      cy.get('input[type="submit"]').click();

      cy.contains('Wrestler was successfully created.');
      cy.contains(`Wrestler${wrestlerCounter}`);
      wrestlerCounter++;
    });
    cy.contains('Tournament Home').click();
  });
});
