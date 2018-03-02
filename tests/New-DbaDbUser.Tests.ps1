$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

<#
Parameters:
- SqlCredential
- Login
- Username
- Force
- EnableException
#>

Describe "$CommandName Unit Tetsts" -Tag "UnitTests" {
    BeforeAll {}
    AfterAll {}

    It "Should throw on an invalid SQL Connection" {
        Mock -ModuleName 'dbatools' Connect-SqlInstance { throw }

        { New-DbaDbUser -SqlInstance 'MadeUpServer' -EnableException } | Should Throw
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {}
    AfterAll{}

    Context "Validate parameters" {
        It "Errors if using Login parameter set and Login is not specified" {
            { New-DbaDbUser -SqlInstance 'MadeUpServer' -Database  -EnableException }
        }
    }

    It "Overwrites an existing user if login already exists" {

    }

    It "Skips overwriting an existing user if login already exists" {

    }

    It "Fails if user already exists for a login and -Force is not used" {

    }

    It "Overwrites an existing user" {

    }

    It "Skips overwriting an existing user" {

    }

    It "Fails if user already exists and -Force is not used" {

    }


}