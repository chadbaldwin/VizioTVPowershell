class VizioTVPower {
    hidden [String]$IPAddress
    hidden [String]$AuthToken

    VizioTVPower([string]$IPAddress, [string]$AuthToken) {
        $this.IPAddress = $IPAddress
        $this.AuthToken = $AuthToken
    }

    [void]On() {
		Set-Power -action 'on' -IPAddress $this.IPAddress -auth $this.AuthToken
    }

    [void]Off() {
		Set-Power -action 'off' -IPAddress $this.IPAddress -auth $this.AuthToken
    }

    [String]Status() {
		Return Get-PowerStatus -IPAddress $this.IPAddress -auth $this.AuthToken
    }
}

class VizioTVInput {
    hidden [String]$IPAddress
    hidden [String]$AuthToken

    VizioTVInput([string]$IPAddress, [string]$AuthToken) {
        $this.IPAddress = $IPAddress
        $this.AuthToken = $AuthToken
    }

	[object[]]List() {
		Return Get-InputList -IPAddress $this.IPAddress -auth $this.AuthToken
	}
	
	[object]Current() {
		Return Get-CurrentInput -IPAddress $this.IPAddress -auth $this.AuthToken
	}
	
	[void]Set([string]$name) {
		Set-Input -name $name -IPAddress $this.IPAddress -auth $this.AuthToken
	}
	
	[string]GetInputByName([string]$name) {
		Return Get-InputByName -Name $name -IPAddress $this.IPAddress -auth $this.AuthToken
	}
}

class VizioTV {
    [String]$IPAddress
    [String]$AuthToken

    [VizioTVPower]$Power
    [VizioTVInput]$Input

    VizioTV([string]$IPAddress, [string]$AuthToken) {
        $this.IPAddress = $IPAddress
        $this.AuthToken = $AuthToken

        $this.Power = [VizioTVPower]::new($this.IPAddress, $this.AuthToken)
        $this.Input = [VizioTVInput]::new($this.IPAddress, $this.AuthToken)
    }
}