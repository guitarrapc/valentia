$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'SymbolicLink' {
    Context "When Test Pass" {
		    It 'Set SymbolicLink. Result should be exist' {
            $createSymbol = "d:\hoge1", "d:\hoge2"
		    Set-ValentiaSymbolicLink -Path (ls d:\ | select -Last 2).FullName -SymbolicPath $createSymbol
            $createSymbol | Should Exist
	    }
		    It 'Get SymbolicLink parameter should be true' {
            $testPath = ls 'd:\' | where Attributes -like '*reparsepoint*'
		    Get-ValentiaSymbolicLink -Path $testPath.FullName | % {$_.Attributes -like '*reparsepoint*'} | Should Be $true
	    }
		    It 'Get only SymbolicLink Pipeline should be true' {
		    ls 'd:\' | where Attributes -like '*reparsepoint*' | Get-ValentiaSymbolicLink | % {$_.Attributes -like '*reparsepoint*'} | Should Be $true
	    }
		    It 'Remove SymbolicLink parameter should be exist' {
            $createSymbol = "d:\hoge1", "d:\hoge2"
            $testPath = ls 'd:\' | where Attributes -like '*reparsepoint*'
		    Remove-ValentiaSymbolicLink -Path $testPath.FullName
            ls d:\ | select -Last 2 | %{$_.fullname} | Should Exist
	    }
    }

    Context "When Test fail" {
		    It 'Set SymbolicLink. Result should not be exist' {
            $createSymbol = "d:\hoge1", "d:\hoge2"
		    Set-ValentiaSymbolicLink -Path (ls d:\ | select -Last 2).FullName -SymbolicPath $createSymbol
            $notCreateSymbol = "d:\hoge3"
            $notCreateSymbol | Should not Exist
	    }
		    It 'Get only SymbolicLink parameter should be null' {
            $testPath = ls 'd:\' | where Attributes -notlike '*reparsepoint*'
		    Get-ValentiaSymbolicLink -Path $testPath.FullName | % {$_.Attrinutes -like '*reparsepoint'} | Should Be $null
	    }
		    It 'Get only SymbolicLink pipeline will should be null' {
		    ls 'd:\' | where Attributes -notlike '*reparsepoint*' | Get-ValentiaSymbolicLink | %{$_.Attrinutes -like '*reparsepoint'} | Should Be $null
	    }
		    It 'Remove SymbolicLink parameter should not be exist' {
            $createSymbol = "d:\hoge1", "d:\hoge2"
            $testPath = ls 'd:\' | where Attributes -like '*reparsepoint*'
		    Remove-ValentiaSymbolicLink -Path $testPath.FullName
            $createSymbol | Should not Exist
	    }
    }
}