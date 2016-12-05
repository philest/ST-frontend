require 'createsend'

# Authenticate with your API key
auth = { :api_key => '3178e57316547310895b48c195da986ee9d65a2bab76724d' }

# The unique identifier for this smart email
smart_email_id = '83aff537-dabc-4c73-af29-7dbee8dc84a7'

# Create a new mailer and define your message
tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)
message = {
  'To' => 'David McPeek <david@joinstorytime.com>',
  'Data' => {
    'adminName' => 'Aubrey Wahl',
    'x-apple-data-detectors' => 'x-apple-data-detectorsTestValue',
    'href^="tel"' => 'href^="tel"TestValue',
    'href^="sms"' => 'href^="sms"TestValue',
    'owa' => 'owaTestValue',
    'flyerLink' => 'flyerLinkTestValue',
    'flyerLinkES' => 'flyerLinkESTestValue',
    'schoolName' => 'StoryTime Elementary'
  }
}

# Send the message and save the response
response = tx_smart_mailer.send(message)