#!/usr/bin/env php
<?php
/*
 * Usage:  credential-validator.php
 */

if ( ! file_exists(__DIR__.'/PHPMailer/PHPMailerAutoload.php') ) {
	echo "You need to install PHPMailer";
	exit(1);
}

require_once(__DIR__.'/PHPMailer/PHPMailerAutoload.php');

$ses_regions = array(
	1 => 'us-east-1',
	2 => 'us-west-2',
	3 => 'eu-west-1',
);

$ses_ports = array (
	1 => 'smtp (port 25)',
	2 => 'ssmtp (port 465',
	3 => 'submission (port 587)',
	4 => 'other (port 2587)',
);

$port_mapping = array (
	1 => 25,
	2 => 465,
	3 => 587,
	4 => 2587,
);

function prompt($prompt = '') {
	echo $prompt;
	return trim(fgets(STDIN), "\n" );
}

echo "Please select one of the 3 SES region\n";
foreach($ses_regions as $k => $r) echo "\t$k - $r\n";
$region = prompt("Which SES region: ");

echo "Pleaase select a valid SMTP port\n";
foreach($ses_ports as $k => $p) echo "\t$k - $p\n";
$port = prompt("Which SMTP Port: ");

$login = prompt("Please enter your SES login (AKIA...): ");
$pass = prompt("Please enter your SES password: ");

$mail = new PHPMailer(true);
$mail->isSMTP();
$mail->SMTPAuth = true;
$mail->Host = 'email-smtp.'.$ses_regions[$region].'.amazonaws.com';
$mail->Port = $port_mapping[$port];
$mail->Username  = $login;
$mail->Password = $pass;

$mail->SMTPSecure = 'tls';
if ( $mail->Port == 465 ) $mail->SMTPSecure = 'ssl';

echo "Summary:\n\t- Server: {$mail->Host}:{$mail->Port}\n\t- User: {$mail->Username}\n\t- Pass: {$mail->Password}\n\t- SSL: {$mail->SMTPSecure}\n";

try {
	$r = $mail->SmtpConnect();
	if ( $r === true ) {
		echo "SMTP authentication succeeded.";
	} else {
		echo "SMTP authntication failed.";
	}
} catch (Exception $e) {
	echo "An execption has been received: ". $e->getMessage();
}

echo "\n";
