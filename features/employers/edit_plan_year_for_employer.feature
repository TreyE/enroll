Feature: Edit Plan Year For Employer

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And staff role person logged in
    And update rating area
    And initial employer ABC Widgets has draft benefit application

    Scenario Outline: Editing exiting plan year
      When ABC Widgets is logged in and on the home page
      And staff role person clicked on benefits tab
      Then employer should see edit plan year button
      And employer clicked on edit plan year button
      Then employer should see form for benefit application and benefit package
      And employer updated <contribution_percent> contribution percent for the application
      And employer clicked on save plan year button
      And employer should see a success message after clicking on save plan year button

      Examples:
        | contribution_percent |
        | 100                  |
        | 0                    |