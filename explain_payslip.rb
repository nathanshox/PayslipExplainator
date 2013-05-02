#!/usr/bin/env ruby

require 'bigdecimal'
require 'bigdecimal/util'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'rbconfig'
require 'yaml'

REPO_LINK = "http://github.com/nathanshox/PayslipExplainator"

SCRIPT_VERSION = 0.5
SCRIPT_VERSION_FILE_URL = "https://raw.github.com/nathanshox/PayslipExplainator/master/version"

class OptionsParser

  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # Set default values here.
    options = OpenStruct.new
    options.config_file_path = File.join(File.dirname(File.expand_path(__FILE__)), 'payslip_config.yml')
    options.pause = false
    options.check_for_update = true

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: explain_payslip.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

      # Cast 'delay' argument to a Float.
      opts.on("--config PATH", "Specify path to config file") do |path|
        options.config_file_path = path
      end

      opts.on("-p", "--[no-]pause", "Pause after each calculation") do |p|
        options.pause = p
      end

      opts.on("-n", "--no-update-check", "Do not check for new version of script") do
        options.check_for_update = false
      end

      opts.separator ""
      opts.separator "Common options:"

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      opts.on_tail("-v", "--version", "Show script version") do
        puts "PayslipExplainator"
        puts "Version: #{SCRIPT_VERSION}"
        exit
      end
    end

    opts.parse!(args)
    options
  end
end

# Misc methods

# Print section header
def print_header(headline)
  puts "\n\n" + "#" * 80
  puts "### #{headline} " + ( "#" * (80 - 5 - headline.length))
end

# Load key from config and return value as Hash
def load_hash_from_config(config, key)
  value = config[key]
  if value.nil?
    abort "Did not find #{key} in config file"
  end
  return value
end

# Load key from config and return value as BigDecimal
def load_bd_from_config(config, key)
  value = config[key]
  if value.nil?
    abort "Did not find #{key} in config file"
  end
  return BigDecimal.new(value.to_s)
end

# Print out hash values, and return sum of values
def print_and_total_hash(input_hash)
  total = BigDecimal.new("0")
  input_hash.each do |key, value|
    v = BigDecimal.new(value.to_s)
    puts "\t#{v.to_digits}\t(#{key.gsub("_", " ").capitalize})"
    total = total + v
  end
  return total
end

def open_browser(url)
  host_os = RbConfig::CONFIG['host_os']
  if host_os =~ /mswin|mingw|cygwin/
    command = "start #{url}"
  elsif host_os =~ /darwin/
    command = "open #{url}"
  elsif host_os =~ /linux/
    command = "xdg-open #{url}"
  end
  system command
end

# This function doesn't return until it reads something from input, thereby pausing execution
# of the script
def pause
  print "\n<<SCRIPT PAUSED. PRESS ANY KEY TO CONTINUE...>>"
  gets.chomp
end

def calculate_paye(taxable_amount, standard_cutoff_rate, tax_credits)
  result = Hash.new

  result['taxable_at_lower_rate_amount'] = taxable_amount > standard_cutoff_rate ? standard_cutoff_rate : taxable_amount
  result['taxable_at_higher_rate_amount'] = taxable_amount > standard_cutoff_rate ? (taxable_amount - standard_cutoff_rate) : BigDecimal.new("0")

  result['tax_payable_at_lower_rate'] = (result['taxable_at_lower_rate_amount'] * BigDecimal.new("0.20"))
  result['tax_payable_at_higher_rate'] = (result['taxable_at_higher_rate_amount'] * BigDecimal.new("0.41"))

  result['paye_pre_tax_credits_deduction'] = result['tax_payable_at_lower_rate'] + result['tax_payable_at_higher_rate']
  result['paye'] = (result['paye_pre_tax_credits_deduction'] - tax_credits).round 2
  return result
end

def calculate_usc(taxable_amount, two_percent_band, four_percent_band)
  result = Hash.new

  result['chargable_at_two'] = taxable_amount > two_percent_band ? two_percent_band : taxable_amount
  result['chargable_at_four'] = taxable_amount > (two_percent_band + four_percent_band) ? four_percent_band : ( taxable_amount > result['chargable_at_two'] ? (taxable_amount - result['chargable_at_two']) : BigDecimal.new("0"))
  result['chargable_at_seven'] = taxable_amount > (two_percent_band + four_percent_band) ? (taxable_amount - (two_percent_band + four_percent_band)) : BigDecimal.new("0")

  result['usc_payable_at_two'] = (result['chargable_at_two'] * BigDecimal.new("0.02"))
  result['usc_payable_at_four'] = (result['chargable_at_four'] * BigDecimal.new("0.04"))
  result['usc_payable_at_seven'] = (result['chargable_at_seven'] * BigDecimal.new("0.07"))

  result['usc'] = (result['usc_payable_at_two'] + result['usc_payable_at_four'] + result['usc_payable_at_seven']).round 2
  return result
end

## START OF MAIN #########################################################################

# Parse arguments
options = OptionsParser.parse(ARGV)

puts "#" * 80
puts "# PAYSLIP EXPLAINATOR"
puts "#" * 80
puts ""
puts "Welcome to the Payslip Explainator. Let's try decrypt your payslip."
puts ""

# Check script version
if options.check_for_update
  begin
    puts "Checking for new version of the script..."
    # TODO Add a timeout here
    latest_version = open(SCRIPT_VERSION_FILE_URL).read.to_f
    if latest_version > SCRIPT_VERSION
      puts "Version #{latest_version} of script is available. You are currently using version #{SCRIPT_VERSION}."
      puts "You can download the latest script from #{REPO_LINK}"
      print "Would you like to download the latest version now? (yes/no) >: "
      if gets.downcase.strip == 'yes'
        puts "Opening browser..."
        exit open_browser(REPO_LINK)
      else
        puts "Continuing execution of this version (#{SCRIPT_VERSION}) of the script"
      end
    else
      puts "You have the latest version of the script"
    end
  rescue
    puts "Couldn't check for latest version of script."
    puts "Are you connected to the internet? Can you access #{REPO_LINK} in your web browser?"
    puts "Continuing execution of script" 
  end
end

# Attempt to load config file ############################################################
if File.exists? options.config_file_path
  config_file = YAML::load_file options.config_file_path
  if config_file
    print "\nYour payslip.yml file has been found and loaded\n\n"
    regular_salary = load_bd_from_config config_file, "regular_salary"
    pension_contribution_percentage = load_bd_from_config config_file, "pension_contribution_percentage"
    espp_contribution_percentage = load_bd_from_config config_file, 'espp'
    car_allowance_hash = load_hash_from_config config_file, "car_allowance"
    salary_sacrifice_hash = load_hash_from_config config_file, "salary_sacrifice"
    benefit_in_kind_hash = load_hash_from_config config_file, "benefit_in_kind"
    misc_deductions_hash = load_hash_from_config config_file, "misc_deductions"
    standard_cutoff_rate = load_bd_from_config config_file, "standard_cutoff_rate"
    tax_credit = load_bd_from_config config_file, "tax_credit"
    usc_two_percent_band = load_bd_from_config config_file, "two_percent_band"
    usc_four_percent_band = load_bd_from_config config_file, "four_percent_band"
  end
else
  abort "Couldn't find #{options.config_file_path}. Does this file exist?"
end

# Get other input values #################################################################
print 'Did you receive a PL&I bonus this month? Enter 0 for no bonus. >: '
pli_bonus = gets.to_d

print 'Did you receive a CAP Award or Connected Recognition Award this month? Enter 0 for no awards or the GROSS total for the awards. >: '
gross_bonus_award = gets.to_d

bik_to_enter = true
print 'Do you have a variable benefit in kind you want to enter? (yes or no) >: '
bik_to_enter = gets.strip == 'yes' ? true : false
while bik_to_enter
  print 'What is the benefit in kind? >: '
  var_bik_key = gets.strip
  print 'How much is the benefit in kind? >: '
  var_bik_value = gets.strip
  benefit_in_kind_hash[var_bik_key] = var_bik_value
  print 'Do you have another variable benefit in kind you want to enter? (yes or no) >: '
  bik_to_enter = gets.strip == 'yes' ? true : false
end

print 'Did you receive any refunds this pay period? Enter 0 for no refunds >: '
refund = gets.to_d

print_header "Input Values"
puts "These are the values the script is using to calculate your payslip\n"
puts "-Regular Salary: #{regular_salary.to_digits}"
puts "-PL&I Bonus: #{pli_bonus.to_digits}"
puts "-CAP Award/Connected Recognition Awards: #{gross_bonus_award.to_digits}"
puts "-Pension Contribution: #{pension_contribution_percentage.to_digits}%"
puts "-ESPP: #{espp_contribution_percentage.to_digits}%"
puts "-Car Allowance: #{car_allowance_hash}"
puts "-Salary Sacrifice: #{salary_sacrifice_hash}"
puts "-Refund: #{refund.to_digits}"
puts "-Benefit in Kind: #{benefit_in_kind_hash}"
puts "-Misc Deductions: #{misc_deductions_hash}"
puts "-PAYE Standard rate cutoff: #{standard_cutoff_rate.to_digits}"
puts "-PAYE Tax credit: #{tax_credit.to_digits}"
puts "-USC 2% Band: #{usc_two_percent_band.to_digits}"
puts "-USC 4% Band: #{usc_four_percent_band.to_digits}"

pause unless !options.pause

# Salary Sacrifices ######################################################################
print_header "Salary Sacrfices"
salary_sacrifice_total = print_and_total_hash salary_sacrifice_hash
puts ""
puts "TOTAL SALARY SACRIFICE = #{salary_sacrifice_total.to_digits}"

pause unless !options.pause

# Car Allowance ##########################################################################
print_header "Car Allowance"
if car_allowance_hash["type"] == "cash"
  puts "Your car allowance is paid in cash so is considered in your Gross Income below"
elsif car_allowance_hash["type"] == "bik"
  puts "Your Car Allowance is a Benefit in Kind so it has been added to that section below"
  benefit_in_kind_hash["car_allowance"] = car_allowance_hash["value"].to_s
else
  puts "You have not specified you are in receipt of Car Allowance."
  puts "If you are, change your config to 'cash' or 'bik' as appropriate"
end

pause unless !options.pause

# Gross Income ###########################################################################
print_header "Gross Income"
puts "Gross Income\t+ #{regular_salary.to_digits}\t\t(Regular salary)"
puts "\t\t+ #{gross_bonus_award.to_digits}\t\t(Total CAP Award/Connected Recognition Awards)"
puts "\t\t+ #{pli_bonus.to_digits}\t\t(PL&I Bonus)"
if car_allowance_hash["type"] == "cash"
  car_allowance = BigDecimal.new(car_allowance_hash["value"].to_s)
  puts "\t\t+ #{car_allowance.to_digits}\t\t(Car Allowance)"
else
  car_allowance = BigDecimal.new("0")
end
puts "\t\t- #{salary_sacrifice_total.to_digits}\t\t(Salary Sacrifices)"
gross_income = regular_salary + gross_bonus_award + pli_bonus + car_allowance - salary_sacrifice_total
puts ""
puts "TOTAL GROSS INCOME = #{gross_income.to_digits}"

pause unless !options.pause

# Calculate Benefit in Kind ##############################################################
print_header "Benefit in Kind"
bik_total = print_and_total_hash benefit_in_kind_hash
puts ""
puts "TOTAL BENEFIT IN KIND = #{bik_total.to_digits}"

pause unless !options.pause

# Calculate Pension Contribution #########################################################
if pension_contribution_percentage > 0
  print_header "Pension Contribution"
  puts "Your pension contribution is #{pension_contribution_percentage.to_digits}%"
  puts ""
  puts "Input for pension contribution = #{regular_salary.to_digits} (Regular Salary)"
  puts ""
  pension_contribution = ((regular_salary / 100) * pension_contribution_percentage).round(2)
  puts "#{regular_salary.to_digits} @ #{pension_contribution_percentage.to_digits}% = #{pension_contribution.to_digits}"
  puts ""
  puts "TOTAL PENSION CONTRIBUTION = #{pension_contribution.to_digits}"
else
  pension_contribution = BigDecimal.new("0")
end

pause unless !options.pause

# Calculate PAYE #########################################################################
print_header "PAYE"
puts "Input for PAYE\t+ #{gross_income.to_digits}\t\t(Gross Income)"
puts "\t\t+ #{bik_total.to_digits}\t\t(Benefit In Kind)"
puts "\t\t- #{pension_contribution.to_digits}\t\t(Pension Contribution)"
paye_input = gross_income + bik_total - pension_contribution
puts "Total Input\t= #{paye_input.to_digits}"
puts ""

paye_result = calculate_paye paye_input, standard_cutoff_rate, tax_credit

puts "#{paye_result['taxable_at_lower_rate_amount'].to_digits} @ 20%\t  #{paye_result['tax_payable_at_lower_rate'].round(2).to_digits}\t(#{paye_result['tax_payable_at_lower_rate'].to_digits})"
puts "#{paye_result['taxable_at_higher_rate_amount'].to_digits} @ 41%\t  #{paye_result['tax_payable_at_higher_rate'].round(2).to_digits}\t(#{paye_result['tax_payable_at_higher_rate'].to_digits})"
puts "\t\t= #{paye_result['paye_pre_tax_credits_deduction'].round(2).to_digits}\t(#{paye_result['paye_pre_tax_credits_deduction'].to_digits})"
puts "\t\t- #{tax_credit.to_digits} (Monthly tax credit)"
puts ""
puts "TOTAL PAYE\t= #{paye_result['paye'].to_digits}"

pause unless !options.pause

# Calculate USC ##########################################################################
print_header "USC"
puts "Input for USC\t+ #{gross_income.to_digits}\t\t(Gross Income)"
puts "\t\t+ #{bik_total.to_digits}\t\t(Benefit In Kind)"
usc_input = gross_income + bik_total
puts "Total Input\t= #{usc_input.to_digits}"
puts ""

usc_result = calculate_usc usc_input, usc_two_percent_band, usc_four_percent_band

puts "#{usc_result['chargable_at_two'].to_digits} @ 2%\t  #{usc_result['usc_payable_at_two'].round(2).to_digits}\t(#{usc_result['usc_payable_at_two'].to_digits})"
puts "#{usc_result['chargable_at_four'].to_digits} @ 4%\t  #{usc_result['usc_payable_at_four'].round(2).to_digits}\t(#{usc_result['usc_payable_at_four'].to_digits})"
puts "#{usc_result['chargable_at_seven'].to_digits} @ 7%\t  #{usc_result['usc_payable_at_seven'].round(2).to_digits}\t(#{usc_result['usc_payable_at_seven'].to_digits})"
puts ""
puts "TOTAL USC\t= #{usc_result['usc'].to_digits}"

pause unless !options.pause

# Calculate PRSI #########################################################################
print_header "PRSI"
puts "Input for PRSI\t+ #{gross_income.to_digits}\t\t(Gross Income)"
puts "\t\t+ #{bik_total.to_digits}\t\t(Benefit In Kind)"
prsi_input = gross_income + bik_total
puts "Total Input\t= #{prsi_input.to_digits}"
puts ""

total_prsi = (prsi_input * BigDecimal.new("0.04")).round(2)
puts "#{prsi_input.to_digits} @ 4% = #{total_prsi.to_digits}"
puts ""
puts "TOTAL PRSI\t= #{total_prsi.to_digits}"

pause unless !options.pause

# Calculate ESPP #########################################################################
if espp_contribution_percentage > 0
  print_header "ESPP"
  puts "Input for ESPP\t+ #{regular_salary.to_digits}\t(Regular Salary)"
  puts "\t\t+ #{pli_bonus.to_digits}\t(PL&I Bonus)"
  espp_input = regular_salary + pli_bonus
  puts "Total Input\t= #{espp_input.to_digits}"
  puts ""

  espp = ((espp_input / 100) * espp_contribution_percentage).round(2)
  puts "#{espp_input.to_digits} @ #{espp_contribution_percentage.to_digits}% = #{espp.to_digits}"
  puts ""
  puts "TOTAL ESPP CONTRIBUTION = #{espp.to_digits}"
else
  espp = BigDecimal.new("0")
end

pause unless !options.pause

# Misc Deductions ########################################################################
print_header "Misc Deductions"
misc_deductions_total = print_and_total_hash misc_deductions_hash
puts ""
puts "TOTAL MISC DEDUCTIONS = #{misc_deductions_total.to_digits}"

pause unless !options.pause

# Net Pay ################################################################################
print_header "Net Pay" 
puts "\t  #{gross_income.to_digits}\t(Gross Income)"
puts "\t+ #{refund.to_digits}\t(Refund)"
puts "\t- #{paye_result['paye'].to_digits}\t(PAYE)"
puts "\t- #{usc_result['usc'].to_digits}\t(USC)"
puts "\t- #{total_prsi.to_digits}\t(PRSI)"
puts "\t- #{pension_contribution.to_digits}\t(Pension Contribution)"
puts "\t- #{espp.to_digits}\t(ESPP)"
puts "\t- #{misc_deductions_total.to_digits}\t(Misc Deductions)"
net_income = gross_income + refund - paye_result['paye'] - usc_result['usc'] - total_prsi - pension_contribution - espp - misc_deductions_total
puts "\t= #{net_income.to_digits}"
puts ""
puts "TOTAL NET INCOME = #{net_income.to_digits}"