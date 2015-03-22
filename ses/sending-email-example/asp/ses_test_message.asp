<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
	<title>SES Simpler email test</title>
</head>

<body>
<%
Dim iMsg, iConf, Flds
Set iMsg = CreateObject("CDO.Message")
Set iConf = CreateObject("CDO.Configuration")

Set Flds = iConf.Fields
Const cdoSendUsingPort = 2

With Flds
.Item("http://schemas.microsoft.com/cdo/configuration/sEndusing") = cdoSendUsingPort
.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "email-smtp.us-west-2.amazonaws.com" ' SES SMTP endpoint (eu-west-1, us-east-1, us-west-2)
.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 2465 'SMTP Port (25, 465, 2465) (Due to limited TLS support, ports 587 and 2587 aren't working)
.Item("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1 'basic
.Item("http://schemas.microsoft.com/cdo/configuration/sendusername") = "AKIAXXXXXXXXXXXXXXXXX" 'SES SMTP Login
.Item("http://schemas.microsoft.com/cdo/configuration/sendpassword") = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ' SES SMTP Password
.Item("http://schemas.microsoft.com/cdo/configuration/smtpusessl") = True
.Item("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout") = 10
.Update
End With

Dim strBody, strHtmlBody, strSubject

strSubject = "Thank you page"
strBody = "Thank you for contacting us. (text)"
strHtmlBody = "<div><font face='Arial' size='-1'>Thank you for contacting Us. (html)"  
strHtmlBody = strHtmlBody & "</div>"

With iMsg
Set .Configuration = iConf
.To = "" ' FIXME
.From = "" ' FIXME
.Subject = strSubject
.TextBody = strBody
.HTMLBody = strHtmlBody
.Send
End With 


If Err Then
	Response.write  "failed"
Else
	Response.write "ok"
End If

Response.flush
    
%>
</body>
</html>
