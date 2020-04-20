Usage:
      ./VistaScrub_20190806.ps1 -ConfigFile <valid configuration file> -SMTPUser <user@mckinstry.com> -SMTPPassword <password> -Evaluate $true|$false

           -ConfigFile is the full path to a valid configuration file.  Example: ".\VPSTAGINGAG_Viewpoint_Settings.xml"
                     The format of the configuration files should be fairly straight forward.  
                     It does support 
                         1..N “Environments”
                         0..N “PRESTEPS” per “Environment”
                         1..N “SCRUBFIELD” per “Environment”
                         0..N “POSTSTEPS” per “Environment”
           -SMTPUser is a valid UPN for an Office 365 enabled user. Example: billo@mckinstry.com
           -SMTPPassword is the password for the provided SMTPUser
           -Evaluate: $true will all the script to run without actually performing any data modifications.
                      $false will allow the logic to actually execute the data modification steps.
