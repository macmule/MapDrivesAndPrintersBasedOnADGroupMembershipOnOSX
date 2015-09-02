----------------------------------------------------------------------------------------------------
--
-- More information: http://macmule.com/2011/09/08/how-to-map-drives-printers-based-on-ad-group-membership-on-osx/
--
-- GitRepo: https://github.com/macmule/MapDrivesAndPrintersBasedOnADGroupMembershipOnOSX
--
-- License: http://macmule.com/license/
--
----------------------------------------------------------------------------------------------------

-------------------------------
--- User Information 
-------------------------------

-- Get the logged in users username
set loggedInUser to do shell script "whoami"

-- Get the Users account UniqueID
set accountType to do shell script "dscl . -read /Users/" & loggedInUser & " | grep UniqueID | cut -c 11-"

-- Get the nodeName from the Users account
set nodeName to do shell script "dscl . -read /Users/" & loggedInUser & " | awk '/^OriginalNodeName:/,/^Password:/' | head -2 | tail -1 | cut -c 2-" 

-- Get the Users group membership from AD
set ADGroups to do shell script "dscl " & quoted form of nodeName & " -read /Users/" & loggedInUser & " | awk '/^dsAttrTypeNative:memberOf:/,/^dsAttrTypeNative:msExchHomeServerName:/'" 

-- Get the Users AD Home Folder
set ADHome to do shell script "dscl " & quoted form of nodeName & " -read /Users/" & loggedInUser & "| grep SMBHome: | cut -c 10- | sed 's/\\\\/\\//g' "

-- Checks to see if account is an AD Account, if its not exit
if accountType is less than 1000 then
 tell me to quit
end if

------------------------------
--- Drives
------------------------------
--Home Folder -- Maps the drive specified in the profile field for the AD User continue if user has no profile path set 
try 
  
  mount volume "smb:" & ADHome 
  
  on error 
  
end try 

-- Checks Group Membership for ADGroups contains user & if they -- are in the correct groups, mount shares. ---------
if ADGroups contains "GROUPNAME" then 
    mount volume "PROTOCOL://SERVERNAME.FQDN/SHARENAME" 
end if 

------------------------------
--- Printers
------------------------------

---- List All Printers 
try 
     set installedPrinters to do shell script "lpstat -a" 
on error 
     set installedPrinters to "" 
end try 

---- Map Printers 
if ADGroups contains "GROUPNAME" then 
     if installedPrinters does not contain "PRINTERNAME" then 
          try 
               do shell script "/usr/sbin/lpadmin -p PRINTERNAME -E -v lpd://PRINTERIP -P PPDLOCATION -L \"PRINTERLOCATION\" -o printer-is-shared=false" 
          on error 
               do shell script "/usr/sbin/lpadmin -p PRINTERNAME -E -v lpd://PRINTERIP -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/Generic.ppd -L \"PRINTERLOCATION\" -o printer-is-shared=false" 
          end try 
     end if 
end if
