{{/*
This template only gives out SSH host certificates for the
host with the given Common Name and DNS Names.

Uses - bootstrapping an ssh host key from an x509 certificate obtained from acme
Note: it completely ignores the requester provided principals and enforces its own
set of principals based on the x509 certificate's DNS Names.
*/}}
{
	"type": {{ toJson .Type }},
	"keyId": {{ toJson .AuthorizationCrt.Subject.CommonName }},
	"principals": {{ toJson .AuthorizationCrt.DNSNames }},
	"extensions": {{ toJson .Extensions }},
	"criticalOptions": {{ toJson .CriticalOptions }}
}