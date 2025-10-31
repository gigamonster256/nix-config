Match all
	TrustedUserCAKeys /etc/ssh/step-ca.pub
	HostCertificate /etc/ssh/{{.User.Certificate}}
	HostKey /etc/ssh/{{.User.Key}}