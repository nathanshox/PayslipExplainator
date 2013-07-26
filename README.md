#PayslipExplainator [![Code Climate](https://codeclimate.com/github/nathanshox/PayslipExplainator.png)](https://codeclimate.com/github/nathanshox/PayslipExplainator)

The Payslip Explainator is a script that can be used
* to verify a monthly payslip
* to break down a payslip into more detail
* to predict the affect a change of benefits would have on net pay

It was originally made for Cisco Ireland employees to help with issues around payroll, but with little or no modification it should be suitable for most workers in Ireland.

## How to use
1. [Download](https://github.com/nathanshox/PayslipExplainator/archive/master.zip) or [clone](https://github.com/nathanshox/PayslipExplainator) the project to your local machine
2. Fill in required values in the config file (```payslip_config.yml```)
3. From a terminal in the project's directory, run the script with the command ```$ruby explain_payslip.rb```
4. The script will ask you for more input such as bonus payments, refunds etc for the pay period
5. _*KABLOOM*_ Your payslip explained!

## Options
You can see all the options for the script by running ```$ruby explain_payslip.rb -h```
```
Usage: explain_payslip.rb [options]

Specific options:
    -c, --config PATH                Specify path to a config file
    -p, --[no-]pause                 Pause after each calculation
    -n, --no-update-check            Do not check for new version of script

Common options:
    -h, --help                       Show this message
    -v, --version                    Show script version
```

## Requirements
You will need:
* Ruby installed
  * Mac and Linux operating systems typically already have Ruby installed
  * There is an installer available for Windows at http://rubyinstaller.org/
  * The script was tested with versions 1.8.7, 1.9.2, 1.9.3, and 2.0.0

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/nathanshox/PayslipExplainator/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
