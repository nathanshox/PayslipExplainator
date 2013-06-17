#PayslipExplainator [![Code Climate](https://codeclimate.com/github/nathanshox/PayslipExplainator.png)](https://codeclimate.com/github/nathanshox/PayslipExplainator)

The Payslip Explainator is a script that can be used
* to verify a monthly payslip
* to break down a payslip into more detail
* to predict the affect a change of benefits would have on net pay

It was originally made for Cisco Ireland employees to help with issues around payroll, but with little or no modification it should be suitable for most workers in Ireland.

## How to use
1. Download the script ([explain_payslip.rb](https://raw.github.com/nathanshox/PayslipExplainator/master/explain_payslip.rb)) and the config file ([payslip_config.yml](https://raw.github.com/nathanshox/PayslipExplainator/master/payslip_config.yml)).
2. Fill in required values in the config file.
3. Run the script with the command ```$ruby explain_payslip.rb```
4. The script will ask you for other items such as bonuses etc for the pay period.

## Options
You can see all the options for the script by running ```$ruby explain_payslip.rb -h```
```
Usage: explain_payslip.rb [options]

Specific options:
        --config PATH                Specify path to config file
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
  * The script was tested with versions 1.8.7, 1.9.3, and 2.0
