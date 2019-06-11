Function filterOutWeirdTags($objectName)
{
    $nonStandardTag='__\w*$'
    $customObjectTag='__c$'

    return ($objectName -match $nonStandardTag -AND $objectName -notmatch $customObjectTag)   
}

Function getMetadataNames($username) 
{
    [System.Collections.ArrayList] $soqlResults = sfdx force:data:soql:query -q "SELECT  QualifiedApiName FROM EntityDefinition" -r csv -u $AUTH_UNAME
    $soqlResults.RemoveAt(0);

    return $soqlResults
}

cd C:\SFMD_Backup\SFMD_Backup

[string] $Config_json_string=Get-Content 'C:\SFMD_Backup\Config.json'
$config_json = ConvertFrom-Json $Config_json_string

$AUTH_UNAME=$config_json.UserName

$SERVER_KEY_PATH=$config_json.ServerKey

$PROJECT_MAN_PATH=$config_json.ProjectManifest

$MetaData_Types_PATH=$config_json.MetaDataTypes

$MetaData_Types= Import-Csv -path $MetaData_Types_Path

[XML]$BLANK_MAN='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>45.0</version>
</Package>'

$CONSUMER_KEY=$config_json.ConsumerKey

#begining of execution

#authenticate
sfdx force:auth:jwt:grant --clientid $CONSUMER_KEY  --jwtkeyfile $SERVER_KEY_PATH --username $AUTH_UNAME

$metaDataNames = getMetadataNames($AUTH_UNAME)

$metaDataNames.ForEach(
{
    if(filterOutWeirdTags($_))
    {
        return #actually continue/ weird powershell behaviour. Has to do with this actually being a function call
        
    }

    $types_element = $BLANK_MAN.CreateElement('types', "http://soap.sforce.com/2006/04/metadata")

    $types_members_element = $BLANK_MAN.CreateElement('members', 'http://soap.sforce.com/2006/04/metadata')
    $types_members_element.InnerText=$_
    $types_element.AppendChild($types_members_element)

    $types_name_element = $BLANK_MAN.CreateElement('name', 'http://soap.sforce.com/2006/04/metadata')
    $types_name_element.InnerText='CustomObject'
    $types_element.AppendChild($types_name_element)

    $BLANK_MAN.Package.AppendChild($types_element)
})

$MetaData_Types.ForEach(
{
    $types_element = $BLANK_MAN.CreateElement('types', "http://soap.sforce.com/2006/04/metadata")

    $types_members_element = $BLANK_MAN.CreateElement('members', 'http://soap.sforce.com/2006/04/metadata')
    $types_members_element.InnerText='*'
    $types_element.AppendChild($types_members_element)

    $types_name_element = $BLANK_MAN.CreateElement('name', 'http://soap.sforce.com/2006/04/metadata')
    $types_name_element.InnerText=$_.type
    $types_element.AppendChild($types_name_element)

    $BLANK_MAN.Package.AppendChild($types_element)
})

$BLANK_MAN.save($PROJECT_MAN)

sfdx force:source:retrieve --manifest $PROJECT_MAN -u $AUTH_UNAME

& 'C:\Program Files\Git\git-bash.exe' C:\SFMD_Backup\git_update_bash_script

echo 'DONE'

