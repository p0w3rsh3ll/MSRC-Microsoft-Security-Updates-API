﻿
# Import module would only work if the module is found in standard locations
# Import-Module -Name MsrcSecurityUpdates -Force
$Error.Clear()
Get-Module -Name MsrcSecurityUpdates | Remove-Module -Force -Verbose:$false
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'MsrcSecurityUpdates.psd1') -Verbose:$false -Force

<#
Get-Help Get-MsrcSecurityUpdate
Get-Help Get-MsrcSecurityUpdate -Examples

Get-Help Get-MsrcCvrfDocument
Get-Help Get-MsrcCvrfDocument -Examples

Get-Help Get-MsrcSecurityBulletinHtml
Get-Help Get-MsrcSecurityBulletinHtml -Examples

Get-Help Get-MsrcCvrfAffectedSoftware
Get-Help Get-MsrcCvrfAffectedSoftware -Examples
#>

Describe 'Function: Get-MsrcSecurityUpdateMSRC (calls the /Updates API)' -Tag 'UpdatesAPICall' {
    It 'Get-MsrcSecurityUpdate - all' {
        Get-MsrcSecurityUpdate |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcSecurityUpdate - by year' {
        Get-MsrcSecurityUpdate -Year 2017 |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcSecurityUpdate - by vulnerability' {
        Get-MsrcSecurityUpdate -Vulnerability CVE-2017-0003 |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcSecurityUpdate - by cvrf' {
        Get-MsrcSecurityUpdate -Cvrf 2017-Jan |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcSecurityUpdate - by date - before' {
        Get-MsrcSecurityUpdate -Before 2018-01-01 |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcSecurityUpdate - by date - after' {
        Get-MsrcSecurityUpdate -After 2017-01-01 |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcSecurityUpdate - by date - before and after' {
        Get-MsrcSecurityUpdate -Before 2018-01-01 -After 2017-10-01 |
        Should Not BeNullOrEmpty
    }
}

Describe 'Function: Get-MsrcCvrfDocument (calls the MSRC /cvrf API)' -Tag 'cvrfAPI' {
    BeforeAll {
        $cvrfDocument = Get-MsrcCvrfDocument -ID 2016-Nov
    }
    It 'Get-MsrcCvrfDocument - 2016-Nov' {
        $cvrfDocument |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcCvrfDocument - 2016-Nov - as XML' {
        Get-MsrcCvrfDocument -ID 2016-Nov -AsXml |
        Should Not BeNullOrEmpty
    }

    Get-MsrcSecurityUpdate | Where-Object { $_.ID -ne '2017-May-B' } |
    Where-Object { $_.ID -eq "$(((Get-Date).AddMonths(-1)).ToString('yyyy-MMM',[System.Globalization.CultureInfo]'en-US'))" } |
    Foreach-Object {
        It "Get-MsrcCvrfDocument - none shall throw: $($PSItem.ID)" {
            {
                $null = Get-MsrcCvrfDocument -ID $PSItem.ID
            } |
            Should Not Throw
        }
    }

    It 'Get-MsrcCvrfDocument for 2017-May-B with Get-MsrcCvrfDocument should throw' {
        {
            Get-MsrcSecurityUpdate | Where-Object { $_.ID -eq '2017-May-B' } |
            Foreach-Object {
                $null = Get-MsrcCvrfDocument -ID $PSItem.ID
            }
        } | Should Throw
    }
}

Describe 'Function: Set-MSRCConfig with proxy' -Tag 'ApiConfig' {
    if (-not ($global:msrcProxy)) {

       Write-Warning -Message 'This test requires you to use Set-MSRCConfig first to set proxy details'
       break
    }

    It 'Get-MsrcSecurityUpdate - all' {
        Get-MsrcSecurityUpdate |
        Should Not BeNullOrEmpty
    }

    It 'Get-MsrcCvrfDocument - 2016-Nov' {
        Get-MsrcCvrfDocument -ID 2016-Nov |
        Should Not BeNullOrEmpty
    }
}

# May still work but not ready yet...
# Describe 'Function: Get-MsrcSecurityBulletinHtml (generates the MSRC Security Bulletin HTML Report)' {
#     It 'Security Bulletin Report' {
#         Get-MsrcCvrfDocument -ID 2016-Nov |
#         Get-MsrcSecurityBulletinHtml |
#         Should Not BeNullOrEmpty
#     }
# }
InModuleScope MsrcSecurityUpdates {

    Describe 'Function: Get-MsrcCvrfAffectedSoftware' -Tag 'Get-MsrcCvrfAffectedSoftware' {
        BeforeAll {
            $cvrfDocument = Get-MsrcCvrfDocument -ID 2016-Nov
        }
        It 'Get-MsrcCvrfAffectedSoftware by pipeline' {
            $cvrfDocument |
            Get-MsrcCvrfAffectedSoftware |
            Should Not BeNullOrEmpty
        }

        It 'Get-MsrcCvrfAffectedSoftware by parameters' {
            Get-MsrcCvrfAffectedSoftware -Vulnerability $cvrfDocument.Vulnerability -ProductTree $cvrfDocument.ProductTree |
            Should Not BeNullOrEmpty
        }
    }

    Describe 'Function: Get-MsrcCvrfProductVulnerability' -Tag 'Get-MsrcCvrfProductVulnerability' {
        BeforeAll {
            $cvrfDocument = Get-MsrcCvrfDocument -ID 2016-Nov
        }
        It 'Get-MsrcCvrfProductVulnerability by pipeline' {
            $cvrfDocument |
            Get-MsrcCvrfProductVulnerability |
            Should Not BeNullOrEmpty
        }

        It 'Get-MsrcCvrfProductVulnerability by parameters' {
            Get-MsrcCvrfProductVulnerability -Vulnerability $cvrfDocument.Vulnerability -ProductTree $cvrfDocument.ProductTree -DocumentTracking $cvrfDocument.DocumentTracking -DocumentTitle $cvrfDocument.DocumentTitle  |
            Should Not BeNullOrEmpty
        }
    }
}

Describe 'Function: Get-MsrcVulnerabilityReportHtml (generates the MSRC Vulnerability Summary HTML Report)' -Tag 'Get-MsrcVulnerabilityReportHtml' {
    BeforeAll {
        $cvrfDocument = Get-MsrcCvrfDocument -ID 2016-Nov
    }
    It 'Vulnerability Summary Report - does not throw' {
        {
            $null = $cvrfDocument |
            Get-MsrcVulnerabilityReportHtml -Verbose:$false -ShowNoProgress -WarningAction SilentlyContinue
        } |
        Should Not Throw
    }

    Get-MsrcSecurityUpdate | Where-Object { $_.ID -ne '2017-May-B' } |
    Where-Object { $_.ID -eq "$(((Get-Date).AddMonths(-1)).ToString('yyyy-MMM',[System.Globalization.CultureInfo]'en-US'))" } |
    Foreach-Object {
        It "Vulnerability Summary Report - none shall throw: $($PSItem.ID)" {
            {
                $null = Get-MsrcCvrfDocument -ID $PSItem.ID |
                Get-MsrcVulnerabilityReportHtml -ShowNoProgress -WarningAction SilentlyContinue
            } |
            Should Not Throw
        }
    }
}

InModuleScope MsrcSecurityUpdates {

	Describe 'Function: Get-KBDownloadUrl (generates the html for KBArticle downloads used in the vulnerability report affected software table)' -Tag 'Get-KBDownloadUrl' {
		BeforeAll {
		    $af = Get-MsrcCvrfDocument -ID 2017-May | Get-MsrcCvrfAffectedSoftware
		}
		It 'Get-KBDownloadUrl by pipeline' {
			{
				$af.KBArticle | Get-KBDownloadUrl
			} |
			Should Not Throw
		}

		It 'Get-KBDownloadUrl by parameters' {
			{
				Get-KBDownloadUrl -KBArticleObject $af.KBArticle
			} |
			Should Not Throw
		}
	}
}

#When a pester test fails, it writes out to stdout, and sets an error in $Error. When invoking powershell from C# it is a lot easier to read the stderr stream.
if($Error)
{
    Write-Error -Message 'A pester test has failed during the validation process'
}
