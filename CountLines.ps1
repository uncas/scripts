#$extensions = (dir -recurse | where {!($_.mode -match "d")} | select-object Extension -unique | Sort-Object Extension)

#foreach ($extension in $extensions) {
#    $value = $extension.Extension
#    "Extension $value"
#}

#return

$extensions = "*.cs", "*.asax", "*.ascx", "*.asp", "*.aspx", "*.bat", "*.cmd", "*.config", "*.cshtml", "*.css", "*.js", "*.master", "*.properties", "*.resources", "*.resx", "*.settings", "*.sql", "*.txt", "*.wsdl", "*.xml", "*.xsd"

$results = @{}

foreach ($extension in $extensions) {
    $lines = (dir -include $extension -exclude *.designer.cs,source/Solutions/packages -recurse | select-string "^(\s*)//" -notMatch | select-string "^(\s*)$" -notMatch).Count
    #$lines = random
    "$lines - $extension"
    $results.Add($extension, $lines)
}

foreach ($result in ($results.GetEnumerator() | Sort-Object Value -descending)) {
    $result
}

return

(dir -include *.cs,*.asax,*.ascx,*.asp,*.aspx,*.bat,*.config,*.cshtml,*.css,*.js,*.master,*.resources,*.resx,*.settings,*.sql,*.txt,*.wsdl,*.xml,*.xsd -exclude *.designer.cs -recurse | select-string "^(\s*)//" -notMatch | select-string "^(\s*)$" -notMatch).Count
