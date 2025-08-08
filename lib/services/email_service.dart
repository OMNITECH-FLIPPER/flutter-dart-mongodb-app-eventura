import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // Email configuration
  static const String _sendGridApiKey = 'YOUR_SENDGRID_API_KEY'; // Replace with your SendGrid API key
  static const String _sendGridUrl = 'https://api.sendgrid.com/v3/mail/send';
  static const String _fromEmail = 'noreply@eventura.com';
  static const String _fromName = 'Eventura Team';

  // SMTP configuration (fallback)
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = 'your-email@gmail.com'; // Replace with your email
  static const String _smtpPassword = 'your-app-password'; // Replace with your app password

  /// Send email using SendGrid API (primary method)
  static Future<bool> sendEmailViaSendGrid({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
  }) async {
    try {
      // For web platform, use mock email service
      if (kIsWeb) {
        debugPrint('📧 MOCK EMAIL: Would send to $to');
        debugPrint('📧 Subject: $subject');
        debugPrint('📧 Content: $htmlContent');
        return true; // Simulate success
      }
      
      final response = await http.post(
        Uri.parse(_sendGridUrl),
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {
                  'email': to,
                }
              ]
            }
          ],
          'from': {
            'email': _fromEmail,
            'name': _fromName,
          },
          'subject': subject,
          'content': [
            {
              'type': 'text/html',
              'value': htmlContent,
            },
            if (textContent != null)
              {
                'type': 'text/plain',
                'value': textContent,
              }
          ],
        }),
      );

      if (response.statusCode == 202) {
        debugPrint('✅ Email sent successfully via SendGrid to: $to');
        return true;
      } else {
        debugPrint('❌ SendGrid API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ SendGrid error: $e');
      return false;
    }
  }

  /// Send email using SMTP (fallback method)
  static Future<bool> sendEmailViaSMTP({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
  }) async {
    try {
      // For web platform, use mock email service
      if (kIsWeb) {
        debugPrint('📧 MOCK SMTP EMAIL: Would send to $to');
        debugPrint('📧 Subject: $subject');
        debugPrint('📧 Content: $htmlContent');
        return true; // Simulate success
      }
      
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address(_smtpUsername, _fromName)
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlContent
        ..text = textContent ?? _stripHtml(htmlContent);

      final sendReport = await send(message, smtpServer);
      debugPrint('✅ Email sent successfully via SMTP to: $to');
      debugPrint('Message sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('❌ SMTP error: $e');
      return false;
    }
  }

  /// Send email with fallback to mock mode
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
  }) async {
    // Try SendGrid first
    bool success = await sendEmailViaSendGrid(
      to: to,
      subject: subject,
      htmlContent: htmlContent,
      textContent: textContent,
    );

    // If SendGrid fails, try SMTP
    if (!success) {
      success = await sendEmailViaSMTP(
        to: to,
        subject: subject,
        htmlContent: htmlContent,
        textContent: textContent,
      );
    }

    // If both fail, use mock mode for development
    if (!success) {
      debugPrint('📧 MOCK EMAIL: Would send to $to');
      debugPrint('📧 Subject: $subject');
      debugPrint('📧 Content: ${textContent ?? _stripHtml(htmlContent)}');
      await Future.delayed(const Duration(milliseconds: 500));
      return true; // Return true in mock mode for development
    }

    return success;
  }

  /// Send welcome email to new users
  static Future<bool> sendWelcomeEmail(User user) async {
    final subject = 'Welcome to Eventura!';
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Welcome to Eventura</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #006B3C; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .button { display: inline-block; padding: 12px 24px; background-color: #006B3C; color: white; text-decoration: none; border-radius: 5px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 Welcome to Eventura!</h1>
          </div>
          <div class="content">
            <h2>Hello ${user.name}!</h2>
            <p>Thank you for joining Eventura, your premier event management platform.</p>
            <p>With your new account, you can:</p>
            <ul>
              <li>Browse and register for exciting events</li>
              <li>Track your event registrations</li>
              <li>Receive notifications about event updates</li>
              <li>Download certificates after attending events</li>
            </ul>
            <p>Your User ID: <strong>${user.userId}</strong></p>
            <p>If you have any questions, feel free to contact our support team.</p>
            <p>Best regards,<br>The Eventura Team</p>
          </div>
          <div class="footer">
            <p>This email was sent to ${user.email}</p>
            <p>&copy; 2024 Eventura. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    ''';

    return await sendEmail(
      to: user.email,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send password reset email
  static Future<bool> sendPasswordResetEmail(String email, String resetToken) async {
    final resetUrl = '${Config.apiBaseUrl}/reset-password?token=$resetToken';
    final subject = 'Password Reset Request - Eventura';
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Password Reset</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #006B3C; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .button { display: inline-block; padding: 12px 24px; background-color: #006B3C; color: white; text-decoration: none; border-radius: 5px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔐 Password Reset Request</h1>
          </div>
          <div class="content">
            <h2>Hello!</h2>
            <p>We received a request to reset your password for your Eventura account.</p>
            <p>Click the button below to reset your password:</p>
            <p style="text-align: center;">
              <a href="$resetUrl" class="button">Reset Password</a>
            </p>
            <div class="warning">
              <strong>Important:</strong>
              <ul>
                <li>This link will expire in 1 hour</li>
                <li>If you didn't request this reset, please ignore this email</li>
                <li>For security, this link can only be used once</li>
              </ul>
            </div>
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; color: #006B3C;">$resetUrl</p>
            <p>Best regards,<br>The Eventura Team</p>
          </div>
          <div class="footer">
            <p>This email was sent to $email</p>
            <p>&copy; 2024 Eventura. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    ''';

    return await sendEmail(
      to: email,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send event registration confirmation
  static Future<bool> sendRegistrationConfirmation(EventRegistration registration, Event event) async {
    final subject = 'Registration Confirmed - ${event.title}';
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Registration Confirmed</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #006B3C; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .event-details { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>✅ Registration Confirmed</h1>
          </div>
          <div class="content">
            <h2>Hello ${registration.userName}!</h2>
            <p>Your registration for <strong>${event.title}</strong> has been confirmed.</p>
            
            <div class="event-details">
              <h3>Event Details:</h3>
              <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
              <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
              <p><strong>Location:</strong> ${event.location}</p>
              <p><strong>Registration ID:</strong> ${registration.id}</p>
            </div>
            
            <p>Please arrive 15 minutes before the event starts. Don't forget to bring your registration confirmation.</p>
            <p>If you need to cancel or modify your registration, please contact the event organizer.</p>
            <p>Best regards,<br>The Eventura Team</p>
          </div>
          <div class="footer">
            <p>&copy; 2024 Eventura. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    ''';

    return await sendEmail(
      to: registration.userEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send bulk notification to users
  static Future<bool> sendBulkNotification(String subject, String message, List<User> users) async {
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>$subject</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #006B3C; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📢 $subject</h1>
          </div>
          <div class="content">
            ${message.replaceAll('\n', '<br>')}
            <p>Best regards,<br>The Eventura Team</p>
          </div>
          <div class="footer">
            <p>&copy; 2024 Eventura. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    ''';

    bool allSuccess = true;
    for (final user in users) {
      final success = await sendEmail(
        to: user.email,
        subject: subject,
        htmlContent: htmlContent,
      );
      if (!success) {
        allSuccess = false;
      }
    }

    return allSuccess;
  }

  /// Send account status change notification
  static Future<bool> sendAccountStatusNotification(User user, String newStatus) async {
    final subject = 'Account Status Update - Eventura';
    final statusMessage = newStatus == 'blocked' 
        ? 'Your account has been blocked. Please contact the administrator for assistance.'
        : 'Your account has been activated. You can now access all features.';
    
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Account Status Update</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: ${newStatus == 'blocked' ? '#dc3545' : '#006B3C'}; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .status-box { background-color: ${newStatus == 'blocked' ? '#f8d7da' : '#d4edda'}; border: 1px solid ${newStatus == 'blocked' ? '#f5c6cb' : '#c3e6cb'}; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>${newStatus == 'blocked' ? '🚫' : '✅'} Account Status Update</h1>
          </div>
          <div class="content">
            <h2>Hello ${user.name}!</h2>
            <div class="status-box">
              <h3>Status: ${newStatus.toUpperCase()}</h3>
              <p>$statusMessage</p>
            </div>
            <p>If you have any questions, please contact our support team.</p>
            <p>Best regards,<br>The Eventura Team</p>
          </div>
          <div class="footer">
            <p>This email was sent to ${user.email}</p>
            <p>&copy; 2024 Eventura. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    ''';

    return await sendEmail(
      to: user.email,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Helper method to strip HTML tags for text content
  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
} 