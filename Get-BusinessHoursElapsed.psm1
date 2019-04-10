
Function Get-BusinessHoursElapsed {

    Param
    (
        [Parameter(Position=0,Mandatory=$True)]
        [DateTime]$FirstDate,
        [Parameter(Position=1,Mandatory=$True)]
        [DateTime]$LastDate,
        [Parameter(Position=2,Mandatory=$False)]
        $BusinessHours,
        [Parameter(Position=3,Mandatory=$False)]
        [array]$StatutoryHolidays
    )

    $StartHours = ($BusinessHours -split ",")[0].trim()
    $EndHours = ($BusinessHours -split ",")[1].trim()

    if ($EndHours -notin 13..23 -or $StartHours -notin 0..12) {
        Write-Error "Business hours are not in 24-Hours format. For example to specify Business Hours between 9 to 5 use folowig -BusinessHours `"9,17`""
        break
    }

    if (!$StatutoryHolidays) { Write-Warning "No Statutory Holidays were supplied"}
    else { Write-Verbose "Bellow Statutory Holidays where supplied: `n$($StatutoryHolidays | Out-string)"}
 
    $TotalBusinessHours = (12 - $StartHours) + ($EndHours - 12)

    Write-Verbose "Supplied Business Hours are between $StartHours and $EndHours"

    $AdditionalElapsedDays = 0
    [DateTime]$NoOfDays =  $FirstDate

    Write-Verbose "Setting Business Hours range for First Date"
    [DateTime]$FirstDayStartTime = get-date (get-date $FirstDate  -Format "yyyy/MM/dd $StartHours`:00:00")
    [DateTime]$FirstDayEndTime = get-date (get-date $FirstDate  -Format "yyyy/MM/dd $EndHours`:00:00")
    Write-Verbose "First day Business Hours are between $FirstDayStartTime and $FirstDayEndTime"

    Write-Verbose "Setting Business Hours range for the Last Date"
    [DateTime]$LastDayStartTime = get-date (get-date $LastDate  -Format "yyyy/MM/dd $StartHours`:00:00")
    [DateTime]$LastDayEndTime = get-date (get-date $LastDate  -Format "yyyy/MM/dd $EndHours`:00:00")
    Write-Verbose "Last day Business Hours are between $LastDayStartTime and $LastDayEndTime"

    if (($FirstDate -ge $FirstDayStartTime -and $FirstDate -le $FirstDayEndTime) -and ($FirstDate.DayOfWeek -notin 6..7) -and ($StatutoryHolidays -notcontains $(Get-Date $FirstDate -UFormat  "%A, %B %d, %Y"))) {
        $FirstDateHours = (New-TimeSpan -Start $FirstDate -End $FirstDayEndTime)
        Write-Verbose "Calculating First Day hours between `"$FirstDate`" and `"$FirstDayEndTime`": $FirstDateHours"
    }
    else {
        Write-Verbose "First Date time is not between business hours or falls on weekend or holidays"
        Write-Verbose "Following Comparison Statement was used -> ((`"$FirstDate`" -ge `"$FirstDayStartTime`" -and `"$FirstDate`" -le `"$FirstDayEndTime`")) -and (`"$($FirstDate.DayOfWeek)`" -notin 6..7) -and (`"`$StatutoryHolidays`" -notcontains `"$(Get-Date $FirstDate -UFormat  "%A, %B %d, %Y")`")))"
        $FirstDateHours = New-TimeSpan -Hours "0"
    }

    if (($LastDate -ge $LastDayStartTime -and $LastDate -le $LastDayEndTime) -and ($LastDate.DayOfWeek -notin 6..7) -and ($StatutoryHolidays -notcontains $(Get-Date $LastDate -UFormat  "%A, %B %d, %Y"))) {
        $LastDateHours = New-TimeSpan -Start $LastDayStartTime -End $LastDate
        Write-Verbose "Calculating Last Day hours between the `"$LastDayStartTime`" and `"$LastDate`": $LastDateHours"       
      
    }
    else {
        Write-Verbose "Last Date is not between business hours"
        Write-Verbose "Following Comparison Statement was used -> ((`"$LastDate`" -ge `"$LastDayEndTime`" -and `"$LastDate`" -le `"$LastDayStartTime`") -and (`"$($LastDate.DayOfWeek)`" -notin 6..7) -and (`"`$StatutoryHolidays`" -notcontains `"$(Get-Date $LastDate -UFormat  "%A, %B %d, %Y")`"))"
        if ($LastDate -ge $LastDayEndTime -and $FirstDate.ToString("yyyy-MM-dd") -ne $LastDate.ToString("yyyy-MM-dd")) {
            Write-Verbose "Last Date is after the End of Business Day so counting $TotalBusinessHours Business hours in"
            $LastDateHours = New-TimeSpan -Hours $TotalBusinessHours
        }
        Else {
            $LastDateHours = New-TimeSpan -Hours "0"
        }

    }

    $ElapsedTime =  $FirstDateHours + $LastDateHours

    Write-Verbose "Calculating hours between First Date and Last Date"
    if ($FirstDate.ToString("yyyy-MM-dd") -eq $LastDate.ToString("yyyy-MM-dd")) {
        
        Write-Verbose "First and Last Date are on the same day"
        Write-Verbose "Comparison done -> $($FirstDate.ToString("yyyy-MM-dd")) -eq $($LastDate.ToString("yyyy-MM-dd"))"
        Write-Verbose "Therefore, calculating just the hours"
        $ElapsedTime = New-TimeSpan $FirstDate $LastDayEndTime

        Write-Verbose "Returing the total hours"
        $ElapsedTime = "$($ElapsedTime.Hours)`:$($ElapsedTime.Minutes)`:$($ElapsedTime.Seconds)"
        #$ElapsedTime = [Math]::Ceiling($ElapsedTime.TotalHours)
        Write-Verbose "Elapsed hours: $ElapsedTime"
        return $ElapsedTime

    }
    elseif ($FirstDate.AddDays(1).ToString("yyyy-MM-dd") -eq $LastDate.ToString("yyyy-MM-dd")) {
    
       
        Write-Verbose "Difference between the First Date and Last Date is less than one day"
        Write-Verbose "Comparison done -> `"$($FirstDate.AddDays(1).ToString("yyyy-MM-dd"))`" -eq `"$($LastDate.ToString("yyyy-MM-dd"))`""
        Write-Verbose "Returing the total hours"
        $ElapsedTime = "$($ElapsedTime.Hours)`:$($ElapsedTime.Minutes)`:$($ElapsedTime.Seconds)"
        Write-Verbose "Elapsed hours: $ElapsedTime"
        return $ElapsedTime

    }
    else {

        Write-Verbose "First and Last days hours calculation completed"
        #if ($NoOfDays.DayOfWeek -in 6..7 -or ($StatutoryHolidays -contains $FirstDate)) { Write-Verbose "Firt or Last date is during weekend or holidays"}
        Write-Verbose "Calculated hours: $ElapsedTime"
        Write-Verbose "Calculating elapsed hours between first and last date"
        do {

            $NoOfDays = $NoOfDays.AddDays(1)
            Write-Verbose "Getting the Next day: $((get-date $NoOfDays -Format F))"
            Write-Verbose ("*" * ("$((get-date $NoOfDays -Format F))").Length)
            Write-Verbose "Checking if it falls in weekdays"
            

            if ($NoOfDays.DayOfWeek -gt 0 -and $NoOfDays.DayOfWeek -lt 6 -and $StatutoryHolidays -notcontains $(get-date $NoOfDays -UFormat  "%A, %B %d, %Y")) {
                Write-Verbose "This is a WeekDay"
                
                Write-Verbose "Counting it for the Business Hours Calculations"
                
                
                $AdditionalElapsedDays++

                Write-Verbose "So far calculated Business Days $AdditionalElapsedDays"
                
            }
            else {
                Write-Verbose "Note: >>>This is a weekend or holiday<<<, skipping..."
            }
            
            Write-Verbose "Calculation will stop when below comparison statement is met."
            Write-Verbose "`"$($NoOfDays.ToString("yyyy-MM-dd"))`" -ne `"$($LastDate.AddDays(-1).ToString("yyyy-MM-dd"))`""

        } while ($NoOfDays.ToString("yyyy-MM-dd") -ne $LastDate.AddDays(-1).ToString("yyyy-MM-dd"))

        Write-Verbose "Comparison was met"
        Write-Verbose "Calculating hours for each day ($(New-TimeSpan -Hours $($AdditionalElapsedDays * $TotalBusinessHours)) hours) and adding to hours for first and last date $ElapsedTime"
        $ElapsedTime = $ElapsedTime + $(New-TimeSpan -Hours $($AdditionalElapsedDays * $TotalBusinessHours))
        #$ElapsedTime = [Math]::Ceiling($ElapsedTime.TotalHours)
        if ($ElapsedTime.Days -gt 0) {
            $TotalHours = $ElapsedTime.Hours + ($ElapsedTime.Days * 24)
            $ElapsedTime = "$TotalHours`:$($ElapsedTime.Minutes)`:$($ElapsedTime.Seconds)"
        }
        else {
            $ElapsedTime = "$($ElapsedTime.Hours)`:$($ElapsedTime.Minutes)`:$($ElapsedTime.Seconds)"
        }
        Write-Verbose "Elapsed Business Hours: $ElapsedTime"
        return $ElapsedTime
    }
}
