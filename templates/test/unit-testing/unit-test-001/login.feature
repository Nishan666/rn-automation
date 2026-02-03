Feature: Login Flow
  As a mobile user
  I want to login to the application
  So that I can access the app features

  Scenario: Successful login with valid credentials
    Given I am on the login screen
    When I enter "test@example.com" in the email field
    And I enter "Test@1234" in the password field
    And I tap the sign in button
    Then I should see the home screen

  Scenario Outline: Login with invalid credentials
    Given I am on the login screen
    When I enter "<email>" in the email field
    And I enter "<password>" in the password field
    And I tap the sign in button
    Then I should see error message "<error>"

    Examples:
      | email             | password   | error                            |
      |                   |            | Email is required                |
      | test@example.com  |            | Password is required             |
      | invalid@email.com | wrong123   | Incorrect email or password      |
