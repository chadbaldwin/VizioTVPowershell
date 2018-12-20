######################################################
# Custom Networking
######################################################
add-type @'
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
	public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {return true;}
}
'@
# Fixes the SSL/TLS authorization issue
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
# Fixes the Expect failure, TV does not support Continue-100 response
[System.Net.ServicePointManager]::Expect100Continue = $false
