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
<!-- TODO: -->
-  If a user attempts to create a new document without a name, the form should be re-displayed and a message should say "A name is required.":
