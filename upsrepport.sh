#March 2026 the original upsreport.sh but adapted by Gemini AI to suit TrueNAS CE 25.xx

#!/bin/sh

# Send UPS report to designated email address for TrueNAS
# Optimized for sendemail.py handling

### Parameters ###

# Specify your email address here:
email="example@gmail.com"

# Set to a value greater than zero to include all available UPSC variables
senddetail=0

freenashostuc=$(hostname -s | tr '[:lower:]' '[:upper:]')
logfile="/mnt/mainraid/scripts/ups_report.tmp"
subject="UPS Status Report for ${freenashostuc}"

### Set email body start ###
# We removed the To, Subject, and MIME lines because sendemail.py handles them
printf "%s\n" "<html><head></head><body><pre style=\"font-size:14px; white-space:pre\">" > ${logfile}

# Get a list of all ups devices using localhost
upslist=$(upsc -l localhost 2>/dev/null)

### Set email body content ###
(
  date "+Time: %Y-%m-%d %H:%M:%S"
  echo ""
  for ups in $upslist; do
    # TrueNAS requires the @localhost suffix
    ups_target="${ups}@localhost"

    ups_type=$(upsc "${ups_target}" device.type 2> /dev/null | tr '[:lower:]' '[:upper:]')
    ups_mfr=$(upsc "${ups_target}" ups.mfr 2> /dev/null)
    ups_model=$(upsc "${ups_target}" ups.model 2> /dev/null)
    ups_serial=$(upsc "${ups_target}" ups.serial 2> /dev/null)
    ups_status=$(upsc "${ups_target}" ups.status 2> /dev/null)
    ups_load=$(upsc "${ups_target}" ups.load 2> /dev/null)
    ups_realpower=$(upsc "${ups_target}" ups.realpower 2> /dev/null)
    ups_realpowernominal=$(upsc "${ups_target}" ups.realpower.nominal 2> /dev/null)
    ups_batterycharge=$(upsc "${ups_target}" battery.charge 2> /dev/null)
    ups_batteryruntime=$(upsc "${ups_target}" battery.runtime 2> /dev/null)
    ups_batteryvoltage=$(upsc "${ups_target}" battery.voltage 2> /dev/null)
    ups_inputvoltage=$(upsc "${ups_target}" input.voltage 2> /dev/null)
    ups_outputvoltage=$(upsc "${ups_target}" output.voltage 2> /dev/null)

    printf "=== %s %s, model %s, serial number %s ===\n\n" "${ups_mfr}" "${ups_type}" "${ups_model}" "${ups_serial}"
    echo "Name: ${ups}"
    echo "Status: ${ups_status}"
    echo "Output Load: ${ups_load}%"
    
    if [ ! -z "${ups_realpower}" ]; then
      echo "Real Power: ${ups_realpower}W"
    fi
    if [ ! -z "${ups_realpowernominal}" ]; then
      echo "Real Power: ${ups_realpowernominal}W (nominal)"
    fi
    if [ ! -z "${ups_inputvoltage}" ]; then
      echo "Input Voltage: ${ups_inputvoltage}V"
    fi
    if [ ! -z "${ups_outputvoltage}" ]; then
      echo "Output Voltage: ${ups_outputvoltage}V"
    fi
    echo "Battery Runtime: ${ups_batteryruntime}s"
    echo "Battery Charge: ${ups_batterycharge}%"
    echo "Battery Voltage: ${ups_batteryvoltage}V"
    echo ""

    if [ $senddetail -gt 0 ]; then
      echo "=== ALL AVAILABLE UPS VARIABLES ==="
      upsc "${ups_target}"
      echo ""
    fi
  done
) >> ${logfile}

### Set email body end ###
printf "%s\n" "</pre></body></html>" >> ${logfile}

### Send report ###
if [ -z "${email}" ]; then
  echo "No email address specified, information available in ${logfile}"
else
  # The Python script will wrap this clean HTML file in its own headers
  python3 /mnt/mainraid/scripts/sendemail.py --subject "${subject}" --to_address "${email}" --mail_body_html "${logfile}"
  
  # Delete temp file once verified
  # rm ${logfile}
fi
