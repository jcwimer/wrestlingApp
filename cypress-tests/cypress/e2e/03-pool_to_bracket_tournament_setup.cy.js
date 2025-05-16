describe('Pool to bracket setup', () => {
  beforeEach(() => {
    // Use cy.session() with the login helper
    cy.session('authUser', () => {
      cy.login(); // Assume cy.login() is defined in commands.js
    });
    cy.visit('/');
    cy.contains('Browse Tournaments').first().click();
    cy.contains('Cypress Test Tournament - Pool to bracket').click();
  });

  it('Setup Pool to bracket tournament. 4 schools, hs boys weights, and wrestlers.', () => {
    // Create boys weights
    // Listen for the confirmation popup and automatically confirm it
    cy.on('window:confirm', (text) => {
      return true; // Simulates clicking "OK"
    });

    // Click the Director Links dropdown then the weights option
    cy.contains('Director Links').first().click();
    cy.contains('Create Boys High School Weights (106-285)').first().click();

    // Add assertions to verify the action
    cy.url().should('include', '/tournaments/');
    cy.contains('106.0');

    // 4 schools
    const schoolNames = Array.from({ length: 4 }, (_, i) => `School ${i + 1}`);
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
      cy.contains('a', schoolName).first().click();
      
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
        // No longer needed - criteria field has been removed
        // cy.get('input[name="wrestler[criteria]"]').type('N/A');
        // cy.get('input[name="wrestler[extra]"]').check();

        // Submit the form
        cy.get('input[type="submit"]').click();

        cy.contains('Wrestler was successfully created.');
        cy.contains(`Wrestler${wrestlerCounter}`);
        wrestlerCounter++;
      });
      cy.get('#tournament-navbar .navbar-brand').contains('Tournament Menu').click();
    });
    
    
    // Go back to the tournament using the tournament navbar link
    // Doing intecept/wait because turbo is causing it to act like a spa
    cy.intercept('GET', /\/tournaments\/\d+$/).as('loadTournamentPageAfterLoop');
    cy.get('#tournament-navbar .navbar-brand').contains('Tournament Menu').click();
    cy.wait('@loadTournamentPageAfterLoop');
    cy.url().should('match', /\/tournaments\/\d+$/); // Check URL is /tournaments/ID
    cy.contains('Cypress Test Tournament - Pool to bracket').should('be.visible'); // Verify page content

    // Create Mat 1
    cy.get('body').then($body => {
      if (!$body.find('h3:contains("Mats")').length || !$body.find('a:contains("Mat 1")').length) {
        cy.contains('Director Links').first().click();
        cy.contains('New Mat').first().click();
        cy.url().should('include', '/mats/new');
        cy.get('input[name="mat[name]"]').type('1'); // Mat name is just '1'
        cy.get('input[type="submit"]').click({ multiple: true });
        cy.contains('a', 'Mat 1').should('be.visible');
      }
    });

    // Generate Matches
    cy.contains('Director Links').first().click();
    cy.contains('Generate Brackets').first().click();
    cy.url().should('include', '/generate_matches');
  });

  it('Should create a new mat.', () => {
    // Create boys weights
    // Listen for the confirmation popup and automatically confirm it
    cy.on('window:confirm', (text) => {
      return true; // Simulates clicking "OK"
    });

    // Create Mat 1
    cy.get('body').then($body => {
      if (!$body.find('h3:contains("Mats")').length || !$body.find('a:contains("Mat 1")').length) {
        cy.contains('Director Links').first().click();
        cy.contains('New Mat').first().click();
        cy.url().should('include', '/mats/new');
        cy.get('input[name="mat[name]"]').type('1'); // Mat name is just '1'
        cy.get('input[type="submit"]').click({ multiple: true });
        cy.contains('a', 'Mat 1').should('be.visible');
      }
    });
   });

  it('Should generate matches.', () => {
    // Generate Matches
    cy.contains('Director Links').first().click();
    cy.contains('Generate Brackets').first().click();
    cy.url().should('include', '/generate_matches');
  });

  // This was creating a CORS error in Cypress. That seems to be a limitation of Cypress.
  // Putting this in a separate test to avoid the CORS error.
  it('Should wait for background jobs to finish.', () => {
    // Define a recursive function to check for job completion
    function waitForJobCompletion(attempt = 0) {
      // Set a limit to prevent infinite loops
      if (attempt > 60) { // 60 attempts = ~10 minutes with our delay
        throw new Error('Background jobs did not complete within the expected time');
      }

      cy.wait(10000); // Wait 10 seconds between checks
      cy.reload();
      
      // Check if any "in progress" alerts exist
      cy.get('body').then($body => {
        const matchAlertExists = $body.find('.alert.alert-info:contains("Match Generation In Progress")').length > 0;
        const bgJobAlertExists = $body.find('.alert.alert-info:contains("Background Jobs In Progress")').length > 0;
        
        if (matchAlertExists || bgJobAlertExists) {
          // Alerts still present, try again
          waitForJobCompletion(attempt + 1);
        } else {
          // No alerts - job is done, continue with test
          cy.log('Background jobs completed after ' + attempt + ' attempts');
        }
      });
    }

    // Start the checking process
    waitForJobCompletion();
  });
});
