paypal-quickbooks
=================

A pretty messy conversion from exported paypal file to quickbooks transactions via IIF file.

Since this is being used by a less-technical friend, here are some brief instructions:

1. Install rvm.
2. Use rvm to install ruby-2.1.1, or alternatively, change .ruby-version to the version you want to use.
3. Use bundler to install the gems this code relies on.
4. Dump your paypal.csv file into the root directory of the code.
5. Run parse.rb
