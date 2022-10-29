# When a user visits the home page, they should see a list of the documents in the CMS: history.txt, changes.txt and about.txt

- Each document within the CMS will have a name that includes an extension.
- This extension will determine how the contents of the page are displayed in
  later steps.


1. make the `public` directory
2. make the appropriate files in that directory
3. create a layout for the home page
4. display the files in the public directory on as an unordered list on the home page

# Implementation for creating new documents

<!-- - When a user views the index page, they should see a link that says "New Document": -->
<!--   1. add a link to index view, that allow for creating a new document -->
<!-- - When a user clicks the "New Document" link, they should be taken to a page with a text input labeled "Add a new document:" and a submit button labeled "Create": -->
<!-- - When a user enters a document name and clicks "Create", they should be redirected to the index page. The name they entered in the form should now appear in the file list. They should see a message that says "$FILENAME was created.", where $FILENAME is the name of the document just created: -->
<!-- -  If a user attempts to create a new document without a name, the form should be re-displayed and a message should say "A name is required.": -->

# Implementation for sign in and sign out

<!-- - When a signed-out user views the index page of the site, they should see a "Sign In" button. -->
<!--   1. add a sign in button to the index page, only if user is not signed in -->

- When a user clicks the "Sign In" button, they should be taken to a new page with a sign in form. The form should contain a text input labeled "Username" and a password input labeled "Password". The form should also contain a submit button labeled "Sign In":
<!-- TODO: -->

- When a user enters the username "admin" and password "secret" into the sign in form and clicks the "Sign In" button, they should be signed in and redirected to the index page. A message should display that says "Welcome!":

- When a user enters any other username and password into the sign in form and clicks the "Sign In" button, the sign in form should be redisplayed and an error message "Invalid credentials" should be shown. The username they entered into the form should appear in the username input.

- When a signed-in user views the index page, they should see a message at the bottom of the page that says "Signed in as $USERNAME.", followed by a button labeled "Sign Out".

- When a signed-in user clicks this "Sign Out" button, they should be signed out of the application and redirected to the index page of the site. They should see a message that says "You have been signed out.".
