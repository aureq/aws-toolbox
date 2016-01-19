import java.util.Properties;
import javax.mail.*;
import javax.mail.internet.*;

public class AmazonSESSample {

	// this code is based on http://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-using-sdk-java.html
	// I added some extra code to show how SSL and TLS are handled differently when using the SES SMTP endpoint
	// You will need to the javax.mail package:
	//   - wget http://java.net/projects/javamail/downloads/download/javax.mail.jar
	// To compile:
	//   - /opt/jdk1.7.0_45/bin/javac -d . -classpath javax.mail.jar AmazonSESSample.java
	// To run:
	//   - /opt/jdk1.7.0_45/bin/java -cp ./javax.mail.jar AmazonSESSample
	// To run in debug:
	//   - /opt/jdk1.7.0_45/bin/java -verbose:class -cp ./javax.mail.jar AmazonSESSample

	static final String FROM = "XXXXXXXXXXXXXXXXXX";   // Replace with your "From" address. This address must be verified.
	static final String TO = "XXXXXXXXXXXXXXXXXX";  // Replace with a "To" address. If your account is still in the 
													   // sandbox, this address must be verified.
	
	static final String BODY = "This email was sent through the Amazon SES SMTP interface by using Java.";
	static final String SUBJECT = "Amazon SES test (SMTP interface accessed using Java)";
	
	// Supply your SMTP credentials below. Note that your SMTP credentials are different from your AWS credentials.
	static final String SMTP_USERNAME = "XXXXXXXXXXXXXXXXXXX";  // Replace with your SMTP username.
	static final String SMTP_PASSWORD = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";  // Replace with your SMTP password.
	
	// Amazon SES SMTP host name. This example uses the US West (Oregon) region.
	static final String HOST = "email-smtp.us-west-2.amazonaws.com";	
	
	// Port we will connect to on the Amazon SES SMTP endpoint. We are choosing port 25 because we will use
	// STARTTLS to encrypt the connection.
	static final int PORT = 2465;

	public static void main(String[] args) throws Exception {

		// Create a Properties object to contain connection configuration information.
		Properties props = System.getProperties();

		// Common properties
		props.put("mail.smtp.auth", "true");
		props.put("mail.smtp.port", PORT); 

		switch(PORT) {
			// SMTPS (SMTP+SSL)
			case 2465:
			case 465:
				// Set properties indicating that we want to use SSL over the SMTP (smtps) to encrypt the connection.
				// As SMTPS has explicit SSL, there are no other properties to set.
				props.put("mail.transport.protocol", "smtps");
			break;

			// SMTP+TLS
			case 2587:
			case 587:
			case 25:
				props.put("mail.transport.protocol", "smtp");
				
				// Set properties indicating that we want to use STARTTLS to encrypt the connection.
				// The SMTP session will begin on an unencrypted connection, and then the client
				// will issue a STARTTLS command to upgrade to an encrypted connection.
				props.put("mail.smtp.starttls.enable", "true");
				props.put("mail.smtp.starttls.required", "true");
			break;
		}

		// Create a Session object to represent a mail session with the specified properties. 
		Session session = Session.getDefaultInstance(props);

		// Create a message with the specified information. 
		MimeMessage msg = new MimeMessage(session);
		msg.setFrom(new InternetAddress(FROM));
		msg.setRecipient(Message.RecipientType.TO, new InternetAddress(TO));
		msg.setSubject(SUBJECT);
		msg.setContent(BODY,"text/plain");
			
		// Create a transport.		
		Transport transport = session.getTransport();
					
		// Send the message.
		try
		{
			System.out.println("Connection details:");
			System.out.println("\t host: "+HOST);
			System.out.println("\t port: "+PORT+"\n");
			System.out.println("Attempting to send an email through the Amazon SES SMTP interface...");
			
			// Connect to Amazon SES using the SMTP username and password you specified above.
			transport.connect(HOST, SMTP_USERNAME, SMTP_PASSWORD);
			
			// Send the email.
			transport.sendMessage(msg, msg.getAllRecipients());
			System.out.println("Email sent!");
		}
		catch (Exception ex) {
			System.out.println("The email was not sent.");
			System.out.println("Error message: " + ex.getMessage());
		}
		finally
		{
			// Close and terminate the connection.
			transport.close();			
		}
	}
}
