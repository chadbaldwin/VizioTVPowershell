$configParams = Get-Content .\Integrations_Config.ps1 | ConvertFrom-Json

function Send-Command {
	param([string]$IPAddress, [string]$path, [string]$method, [string]$auth, [string]$data)

	[uri]$uri = 'https://'+$IPAddress+':'+'7345'+$path
	
	If ($method -eq 'GET') {
		$response = Invoke-RestMethod -Uri $uri -Method $method -Headers @{AUTH=$auth}
	} ElseIf ($method -eq 'PUT') {
		If ($path -eq '/pairing/start' -or $path -eq '/pairing/pair') {
			$response = Invoke-RestMethod -Uri $uri -Method $method -Body $data -ContentType 'application/json'
		} Else {
			$response = Invoke-RestMethod -Uri $uri -Method $method -Headers @{AUTH=$auth} -Body $data -ContentType 'application/json'
		}
	}
	return $response
}

function Create-AuthKey {
	param([string]$deviceName, [int]$deviceId, [string]$IPAddress)

	$payload = @{
		DEVICE_ID=$deviceId;
		DEVICE_NAME=$deviceName
	} | ConvertTo-Json

	$response = Send-Command -path '/pairing/start' -Method 'PUT' -data $payload -ip $IPAddress

	$tvPin = Read-Host -Prompt 'Input the Pin displayed on the screen: '
	$tvPin = $tvPin

	$payload = @{
		DEVICE_ID=$deviceId;
		CHALLENGE_TYPE=$response.ITEM.CHALLENGE_TYPE;
		RESPONSE_VALUE=$tvPin;
		PAIRING_REQ_TOKEN=$response.ITEM.PAIRING_REQ_TOKEN
	} | ConvertTo-Json

	$response = Send-Command -path '/pairing/pair' -Method PUT -data $payload -ip $IPAddress
	return $response
}

function Get-PowerStatus {
	param([string]$IPAddress, [string]$auth)
	
	$response = Send-Command -path '/state/device/power_mode' -method 'GET' -IPAddress $IPAddress -auth $auth
	
	$pwrStatus = $response.ITEMS.VALUE
	
	If ($pwrStatus -eq 1) {
		return 'on'
	} ElseIf ($pwrStatus -eq 0) {
		return 'off'
	}
}

function Set-Power {
	param([string]$action, [string]$IPAddress, [string]$auth)
	
	$pwrStatus = Get-PowerStatus -IPAddress $IPAddress -auth $auth
	
	If ($action -eq 'on' -and $pwrStatus -eq 'off') {
		$code = 1
	} ElseIf ($action -eq 'off' -and $pwrStatus -eq 'on') {
		$code = 0
	} Else {
		return
	}
	
	$data = @{KEYLIST = @(@{CODESET=11; CODE=$code; ACTION='KEYPRESS'})} | ConvertTo-Json
	$response = Send-Command -path '/key_command' -method 'PUT' -data $data -IPAddress $IPAddress -auth $auth
	return
}

function Get-InputList {
	param([string]$IPAddress, [string]$auth)

	$response = Send-Command -path '/menu_native/dynamic/tv_settings/devices/name_input' -method GET -IPAddress $IPAddress -auth $auth
	return $response.ITEMS	
}

function Get-CurrentInput {
	param([string]$IPAddress, [string]$auth)

	$response = Send-Command -path '/menu_native/dynamic/tv_settings/devices/current_input' -method GET -IPAddress $IPAddress -auth $auth
	return $response.ITEMS
}

function Get-InputByName {
	param([string]$name, [string]$IPAddress, [string]$auth)
	
	$inputs = Get-InputList -IPAddress $IPAddress -auth $auth

	$inputs | ForEach {
		If ($_.VALUE.NAME -eq $name) {
			return $_.NAME
		}
	}
}

function Set-Input {
	param([string]$name, [string]$IPAddress, [string]$auth)

	$inputName = Get-InputByName -Name $name -IPAddress $IPAddress -auth $auth
	$currentInput = Get-CurrentInput -IPAddress $IPAddress -auth $auth
	
	# If the TV is already on the correct input, then just turn it on, otherwise set the input (by default turns TV on)
	if ($inputName -eq $currentInput.VALUE) {
		$pwrStatus = Get-PowerStatus -IPAddress $IPAddress -auth $auth
		if ($pwrStatus -eq 'off') {
			Set-Power -action 'on' -IPAddress $IPAddress -auth $auth
		}
	} else {
		$data = @{REQUEST='MODIFY'; VALUE=$inputName; HASHVAL=$currentInput.HASHVAL}|ConvertTo-Json
		Send-Command -path '/menu_native/dynamic/tv_settings/devices/current_input' -method 'PUT' -data $data -IPAddress $IPAddress -auth $auth
	}
}