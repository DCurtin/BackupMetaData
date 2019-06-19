Function filterOutWeirdTags($objectName)
{
    $nonStandardTag='__\w*$'
    $customObjectTag='__c$'

    return ($objectName -match $nonStandardTag -AND $objectName -notmatch $customObjectTag)   
}

Function getObjectMetadataNames($username) 
{
    [System.Collections.ArrayList] $soqlResults = sfdx force:data:soql:query -q "SELECT  QualifiedApiName FROM EntityDefinition" -r csv -u $username
    $soqlResults.RemoveAt(0);

    return $soqlResults
}

Function getReportMetadata($username)
{
    [System.Collections.ArrayList] $soqlResults = sfdx force:data:soql:query -q "SELECT Id, Developername, Name, FolderName FROM Report" -r csv -u $username
    return generateMappedObjectFromCSV($soqlResults)
}

Function getFolderMetadata($username)
{
    [System.Collections.ArrayList] $soqlResults = sfdx force:data:soql:query -q "SELECT Id, Developername, Type, ParentId FROM Folder" -r csv -u $username
    return generateMappedObjectFromCSV($soqlResults)
}

Function generateObjectPath($object ,$folderMapping)
{
    $path=$object.Developername

    $folderMapping
}

Function generateMappedObjectFromCSV
{
    param(
    $csvArray
    )

    $headerString = $csvArray[0];
    $headerElements = $headerString.split(',');
    #echo $headerElements
    $csvArray.RemoveAt(0);
    

    $object = [ordered]@{};
    
    Foreach($headerElement in $headerElements)
    {
        $object.add($headerElement, [System.Collections.ArrayList] @());
    }
    
   Foreach($item in $csvArray)
    {
        $elements = $item.split(',');
        for($index=0; $index -lt $elements.count; ++$index)
        {
            #echo "$index header $($object[$index]) value $($elements[$index])"
            $object[$index].add($elements[$index]);
        }
    }
     <##$csvObject = ConvertTo-Csv $object#>
    return $object;
}

cd F:\SFMD_Backup\SFMD_Backup

[string] $Config_json_string=Get-Content 'F:\SFMD_Backup\Config.json'
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

$metaDataNames = getObjectMetadataNames($AUTH_UNAME)
$reports = getReportMetadataNames($AUTH_UNAME)

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

$reports.ForEach(
{
    <#
        
    #>
})

$BLANK_MAN.save($PROJECT_MAN_PATH)

#sfdx force:source:retrieve --manifest $PROJECT_MAN_PATH -u $AUTH_UNAME
#& 'C:\Program Files\Git\git-bash.exe' F:\SFMD_Backup\git_update_bash_script

echo 'DONE'

