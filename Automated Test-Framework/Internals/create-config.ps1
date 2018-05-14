<#
    Create Configuration file for TestEnvironment
#>
@{
    general = @(
        [PSCustomObject] @{
            Author       = 'Martin Walther'
            Version      = '1.0.0.0000'
        }
    )
    startscript = @(
        [PSCustomObject] @{
            Configfolder = 'Config'
            Internals    = 'Internals'
            Logfolder    = 'Logs'
            Scriptfolder = 'Tests'    
            Reportfolder = 'Reports'
            PesterConfig = 'config.pester.json'
            Logfile      = 'TestEnvironment.log'
            JsonFile     = 'TestEnvironment.json'
            HtmlFile     = 'TestEnvironment.html'
            XmlFile      = 'TestEnvironment.xml'
        }
    )
} | ConvertTo-Json | Out-File '..\Config\config.json' -Force