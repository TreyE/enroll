Feature: As a Super Admin I will be the only user
  that is able to see & access the "Create Plan Year" Feature.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And this employer has not setup a benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer

  Scenario: HBX Staff with Super Admin subroles should see Create Plan Year button
    Then the user will see the Create Plan Year button

  Scenario: HBX Staff with Super Admin subroles should see the Create Plan Year Form
    When the user clicks the Create Plan Year button for this Employer
    Then the user will see the Create Plan Year option row

  Scenario: Submit button will be disabled until all required fields have been filled.
    When the user clicks the Create Plan Year button for this Employer
    Then the Create Plan Year form submit button will be disabled
    When the user completely fills out the Create Plan Year Form
    #Then the Create Plan Year form submit button will not be disabled

  Scenario: Cancel the Create Plan Year new benefit application
    #When the user clicks the Create Plan Year button for this Employer
    #Then the user will see the Create Plan Year option row
    #When the user clicks the X icon on the Create Plan Year form
    #Then the Create Plan Year option row will no longer be visible
