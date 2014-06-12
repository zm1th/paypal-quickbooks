paypal-quickbooks
=================

A pretty messy conversion from exported paypal file to quickbooks transactions via IIF file.

Usage notes
-----------

Since this is being used by a less-technical friend, here are some brief instructions:

0. Check out the code somewhere on your computer using git.
1. Install rvm to help manage ruby versions.
2. Use rvm to install ruby-2.1.1, or alternatively, change .ruby-version to the version you want to use, or simply ignore the ruby version. The code should work with most versions of ruby.
3. Use bundler to install the gems this code relies on, or install them manually using "gem install"
4. Dump your paypal.csv file into the root directory of the code.
5. Run parse.rb

paypal.csv column headers:
--------------------------

Source,Date created,Time created,Invoice date,Due date,Payment date,To email,Invoice number,Item name,Item quantity,Item unit price,Item total,Total invoice amount
