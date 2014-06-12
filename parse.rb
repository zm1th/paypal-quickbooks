#!/usr/bin/env ruby
# the above line tells this script how to find ruby if it is executed directly
# and on your windows box you may need to update it to something else

require 'singleton' # ruby built-in
require 'csv'       # ruby built-in
require 'riif'      # gem for generating iif files
# require 'byebug'  # for debugging

# Easy enough to add in columns to this guy's riif stuff if you need to
# Riif::DSL::Spl::HEADER_COLUMNS << :autostax
# Riif::DSL::Trns::HEADER_COLUMNS << :tax # no effect, quickbooks ignores

# this is an export from paypal. Not included in repo
paypal_file = File.join(File.dirname(__FILE__), 'paypal.csv')

# whatever
class FakeCounter
  include Singleton
  def initialize; @counter = 1000; end
  def next; @counter += 1; end
end

# I thought this was a method, must be an active support thing
class Array
  def sum
    inject(0) {|sum, e| sum += e}
  end
end

# the paypal file has n + 1 lines per customer, where n is the number
# of products purchased. The extra line is a subtotal line. This
# transaction class has one instance per product line, ignoring
# subtotals.
class Transaction

  def total
    @unit_price.to_f * @item_qty.to_f
  end

  # paypal.csv column names to instance variable names mapping
  COLUMN_MAPPINGS = {
    'Payment date' => :payment_date,
    'To email' => :email,
    'Invoice number' => :invoice,
    'Item name' => :item_name,
    'Item quantity' => :item_qty,
    'Item unit price' => :unit_price
  }

  # allow access to instance variables with dot syntax
  COLUMN_MAPPINGS.values.each do |ivar|
    self.send :attr_accessor, ivar
  end

  # create a transaction for each from in the csv file. It only has
  # about 1000 rows, so it can all be in memory
  def self.from_csv_row(row)
    return nil if row['Total invoice amount'].to_i > 0    # ignore subtotal rows
    ret = Transaction.new
    COLUMN_MAPPINGS.each do |csv_name, name|
      ret.instance_variable_set("@#{name}", row[csv_name])
    end
    ret
  end

  # pass an array of transactions meant to be on the same invoice,
  # create sales receipt entries in iif file
  def self.iif(transactions)
    Riif::IIF.new do

      trns do
        row do
          trnsid FakeCounter.instance.next
          trnstype 'SALES RECEIPT'
          date transactions.first.payment_date
          accnt 'Accounts Receivable'
          name 'Paypal Customer'
          amount transactions.map(&:total).sum       # yes, a positive amt here, negative in SPL
          docnum transactions.first.invoice.to_i + 20
          memo transactions.first.email.to_s[0...30] # discovered max field length is 30, crashes went away
        end

        transactions.each_with_index do |curr_trans, idx|
          spl do
            row do
              splid idx
              trnstype 'SALES RECEIPT'
              date curr_trans.payment_date
              accnt 'Merchandise Sales'
              amount -curr_trans.total
              qnty -(curr_trans.item_qty.to_i)          # yes, a negative quantity with a negative amt.
              price curr_trans.unit_price
              invitem curr_trans.item_name.to_s[0...30] # discovered max field length is 30, crashes went away
              taxable 'N'
            end
          end
        end
      end
    end
  end
end


# helpers for chunking files.
def filename(count = 0)
  "_paypal_#{count.to_s.rjust(4, '0')}.iif"
end
    
def next_file(count = 0)
  File.open(filename(count), 'w')
end

slice_size = 5000 # change slice size to create chunked files. Right now this will export one big file.
count = 0 # running count for number of transactions already handled.


# here's where we do the actual work
all_transactions = {}

# group transactions from CSV file by invoice number
CSV.foreach(paypal_file, :headers => true) do |row|
  if curr = Transaction.from_csv_row(row)
    all_transactions[curr.invoice] ||= []
    all_transactions[curr.invoice] << curr
  end
end

# open first file for writing
f = next_file

all_transactions.each do |invoice_number, transactions|
  # next if invoice_number.to_i <= 180    # start at 181, since the last manually entered trans was 180
  count += 1
  # here's the chunked files magic
  if count % slice_size == 0
    f.close # clean up previous file
    f = next_file(count)
  end    
  iif_data = Transaction.iif(transactions)

  # write the current invoice to file, with a SPL record for each transaction
  f.puts iif_data.output
end

# clean up
f.close
