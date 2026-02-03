const { Given, When, Then } = require('@wdio/cucumber-framework');

Given(/^I am on the login screen$/, async () => {
    const emailInput = await $('~email-input');
    await emailInput.waitForDisplayed({ timeout: 5000 });
});

When(/^I enter {string} in the email field$/, async (email) => {
    const emailInput = await $('~email-input');
    await emailInput.setValue(email);
});

When(/^I enter {string} in the password field$/, async (password) => {
    const passwordInput = await $('~password-input');
    await passwordInput.setValue(password);
});

When(/^I tap the sign in button$/, async () => {
    const signInButton = await $('~sign-in-button');
    await signInButton.click();
});

Then(/^I should see the home screen$/, async () => {
    const homeScreen = await $('~home-screen');
    await homeScreen.waitForDisplayed({ timeout: 10000 });
});

Then(/^I should see error message {string}$/, async (errorMessage) => {
    const errorElement = await $('~error-message');
    await errorElement.waitForDisplayed({ timeout: 5000 });
    const text = await errorElement.getText();
    await expect(text).toContain(errorMessage);
});
