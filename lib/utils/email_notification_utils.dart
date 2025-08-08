import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../services/email_service.dart';
import '../services/mongodb_notification_service.dart';

class EmailNotificationUtils {
  /// Send event creation notification to admin
  static Future<bool> sendEventCreationNotification(Event event, User organizer) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Event Creation');
      debugPrint('To: Admin');
      debugPrint('Subject: New Event Created - ${event.title}');
      debugPrint('Content: Organizer ${organizer.name} has created a new event "${event.title}" scheduled for ${event.eventDate}');
      debugPrint('Event Details: ${event.location}, ${event.totalSlots} slots');
      
      // Send email notification
      final emailSuccess = await EmailService.sendEmail(
        to: 'admin@eventura.com', // Replace with actual admin email
        subject: 'New Event Created - ${event.title}',
        htmlContent: '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>New Event Created</title>
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
                <h1>🎉 New Event Created</h1>
              </div>
              <div class="content">
                <h2>Hello Admin!</h2>
                <p>A new event has been created by organizer <strong>${organizer.name}</strong>.</p>
                
                <div class="event-details">
                  <h3>Event Details:</h3>
                  <p><strong>Title:</strong> ${event.title}</p>
                  <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
                  <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
                  <p><strong>Location:</strong> ${event.location}</p>
                  <p><strong>Total Slots:</strong> ${event.totalSlots}</p>
                  <p><strong>Available Slots:</strong> ${event.availableSlots}</p>
                </div>
                
                <p>Please review the event details and approve if necessary.</p>
                <p>Best regards,<br>The Eventura Team</p>
              </div>
              <div class="footer">
                <p>&copy; 2024 Eventura. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        ''',
      );

      // Send MongoDB notification to admin topic
      final notificationSuccess = await MongoDBNotificationService.sendNotificationToTopic(
        topic: 'admin',
        title: 'New Event Created',
        body: 'Organizer ${organizer.name} has created a new event "${event.title}"',
        data: {
          'type': 'event_creation',
          'eventId': event.id,
          'organizerId': organizer.id,
          'organizerName': organizer.name,
        },
        type: 'event_creation',
      );
      
      return emailSuccess && notificationSuccess;
    } catch (e) {
      debugPrint('Error sending event creation notification: $e');
      return false;
    }
  }

  /// Send event update notification to registered users
  static Future<bool> sendEventUpdateNotification(Event event, List<EventRegistration> registrations) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Event Update');
      debugPrint('To: ${registrations.length} registered users');
      debugPrint('Subject: Event Update - ${event.title}');
      debugPrint('Content: The event "${event.title}" has been updated. Please check the app for latest details.');
      
      bool allSuccess = true;
      for (final registration in registrations) {
        debugPrint('Sending to: ${registration.userName} (${registration.userId})');
        
        final success = await EmailService.sendEmail(
          to: registration.userEmail,
          subject: 'Event Update - ${event.title}',
          htmlContent: '''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>Event Update</title>
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
                  <h1>📢 Event Update</h1>
                </div>
                <div class="content">
                  <h2>Hello ${registration.userName}!</h2>
                  <p>The event <strong>${event.title}</strong> has been updated.</p>
                  
                  <div class="event-details">
                    <h3>Updated Event Details:</h3>
                    <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
                    <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
                    <p><strong>Location:</strong> ${event.location}</p>
                    <p><strong>Available Slots:</strong> ${event.availableSlots}</p>
                  </div>
                  
                  <p>Please check the app for the latest event details.</p>
                  <p>Best regards,<br>The Eventura Team</p>
                </div>
                <div class="footer">
                  <p>&copy; 2024 Eventura. All rights reserved.</p>
                </div>
              </div>
            </body>
            </html>
          ''',
        );
        
        if (!success) {
          allSuccess = false;
        }
      }
      
      return allSuccess;
    } catch (e) {
      debugPrint('Error sending event update notification: $e');
      return false;
    }
  }

  /// Send event cancellation notification
  static Future<bool> sendEventCancellationNotification(Event event, List<EventRegistration> registrations) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Event Cancellation');
      debugPrint('To: ${registrations.length} registered users');
      debugPrint('Subject: Event Cancelled - ${event.title}');
      debugPrint('Content: The event "${event.title}" scheduled for ${event.eventDate} has been cancelled. We apologize for any inconvenience.');
      
      bool allSuccess = true;
      for (final registration in registrations) {
        debugPrint('Sending cancellation notice to: ${registration.userName}');
        
        final success = await EmailService.sendEmail(
          to: registration.userEmail,
          subject: 'Event Cancelled - ${event.title}',
          htmlContent: '''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>Event Cancelled</title>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background-color: #f9f9f9; }
                .event-details { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
                .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>❌ Event Cancelled</h1>
                </div>
                <div class="content">
                  <h2>Hello ${registration.userName}!</h2>
                  <p>We regret to inform you that the event <strong>${event.title}</strong> has been cancelled.</p>
                  
                  <div class="event-details">
                    <h3>Cancelled Event Details:</h3>
                    <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
                    <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
                    <p><strong>Location:</strong> ${event.location}</p>
                  </div>
                  
                  <p>We apologize for any inconvenience this may cause. Please check the app for other available events.</p>
                  <p>Best regards,<br>The Eventura Team</p>
                </div>
                <div class="footer">
                  <p>&copy; 2024 Eventura. All rights reserved.</p>
                </div>
              </div>
            </body>
            </html>
          ''',
        );
        
        if (!success) {
          allSuccess = false;
        }
      }
      
      return allSuccess;
    } catch (e) {
      debugPrint('Error sending event cancellation notification: $e');
      return false;
    }
  }

  /// Send registration confirmation notification
  static Future<bool> sendRegistrationConfirmationNotification(EventRegistration registration, Event event) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Registration Confirmation');
      debugPrint('To: ${registration.userName} (${registration.userId})');
      debugPrint('Subject: Registration Confirmed - ${event.title}');
      debugPrint('Content: Your registration for "${event.title}" has been confirmed. Event details: ${event.eventDate} at ${event.location}');
      
      // Send email notification
      final emailSuccess = await EmailService.sendRegistrationConfirmation(registration, event);
      
      // Send MongoDB notification to user
      final notificationSuccess = await MongoDBNotificationService.sendNotificationToUser(
        userId: registration.userId,
        title: 'Registration Confirmed',
        body: 'Your registration for "${event.title}" has been confirmed',
        data: {
          'type': 'registration_confirmed',
          'eventId': event.id,
          'eventTitle': event.title,
          'eventDate': event.eventDate.toIso8601String(),
          'location': event.location,
        },
        type: 'registration_confirmed',
      );
      
      return emailSuccess && notificationSuccess;
    } catch (e) {
      debugPrint('Error sending registration confirmation: $e');
      return false;
    }
  }

  /// Send attendance confirmation notification
  static Future<bool> sendAttendanceConfirmationNotification(EventRegistration registration, Event event, bool attended) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Attendance Confirmation');
      debugPrint('To: ${registration.userName} (${registration.userId})');
      debugPrint('Subject: Attendance ${attended ? 'Confirmed' : 'Marked as Missed'} - ${event.title}');
      
      if (attended) {
        debugPrint('Content: Your attendance for "${event.title}" has been confirmed. A certificate has been generated and is available for download.');
      } else {
        debugPrint('Content: You were marked as not attended for "${event.title}". If this is an error, please contact the organizer.');
      }
      
      return await EmailService.sendEmail(
        to: registration.userEmail,
        subject: 'Attendance ${attended ? 'Confirmed' : 'Marked as Missed'} - ${event.title}',
        htmlContent: '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>Attendance ${attended ? 'Confirmed' : 'Missed'}</title>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: ${attended ? '#28a745' : '#dc3545'}; color: white; padding: 20px; text-align: center; }
              .content { padding: 20px; background-color: #f9f9f9; }
              .event-details { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>${attended ? '✅' : '❌'} Attendance ${attended ? 'Confirmed' : 'Missed'}</h1>
              </div>
              <div class="content">
                <h2>Hello ${registration.userName}!</h2>
                ${attended 
                  ? '<p>Your attendance for <strong>${event.title}</strong> has been confirmed.</p>'
                  : '<p>You were marked as not attended for <strong>${event.title}</strong>.</p>'
                }
                
                <div class="event-details">
                  <h3>Event Details:</h3>
                  <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
                  <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
                  <p><strong>Location:</strong> ${event.location}</p>
                </div>
                
                ${attended 
                  ? '<p>A certificate has been generated and is available for download in the app.</p>'
                  : '<p>If this is an error, please contact the event organizer.</p>'
                }
                <p>Best regards,<br>The Eventura Team</p>
              </div>
              <div class="footer">
                <p>&copy; 2024 Eventura. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        ''',
      );
    } catch (e) {
      debugPrint('Error sending attendance confirmation: $e');
      return false;
    }
  }

  /// Send reminder notification before event
  static Future<bool> sendEventReminderNotification(Event event, List<EventRegistration> registrations) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Event Reminder');
      debugPrint('To: ${registrations.length} registered users');
      debugPrint('Subject: Reminder - ${event.title} Tomorrow');
      debugPrint('Content: This is a friendly reminder that "${event.title}" is scheduled for tomorrow at ${event.location}. Please arrive on time.');
      
      bool allSuccess = true;
      for (final registration in registrations) {
        debugPrint('Sending reminder to: ${registration.userName}');
        
        final success = await EmailService.sendEmail(
          to: registration.userEmail,
          subject: 'Reminder - ${event.title} Tomorrow',
          htmlContent: '''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>Event Reminder</title>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #ffc107; color: #333; padding: 20px; text-align: center; }
                .content { padding: 20px; background-color: #f9f9f9; }
                .event-details { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
                .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>⏰ Event Reminder</h1>
                </div>
                <div class="content">
                  <h2>Hello ${registration.userName}!</h2>
                  <p>This is a friendly reminder that <strong>${event.title}</strong> is scheduled for tomorrow.</p>
                  
                  <div class="event-details">
                    <h3>Event Details:</h3>
                    <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
                    <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
                    <p><strong>Location:</strong> ${event.location}</p>
                  </div>
                  
                  <p>Please arrive 15 minutes before the event starts. Don't forget to bring your registration confirmation.</p>
                  <p>Best regards,<br>The Eventura Team</p>
                </div>
                <div class="footer">
                  <p>&copy; 2024 Eventura. All rights reserved.</p>
                </div>
              </div>
            </body>
            </html>
          ''',
        );
        
        if (!success) {
          allSuccess = false;
        }
      }
      
      return allSuccess;
    } catch (e) {
      debugPrint('Error sending event reminder: $e');
      return false;
    }
  }

  /// Send welcome notification to new users
  static Future<bool> sendWelcomeNotification(User user) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Welcome');
      debugPrint('To: ${user.name} (${user.email})');
      debugPrint('Subject: Welcome to Eventura!');
      debugPrint('Content: Welcome ${user.name}! Thank you for joining Eventura. You can now browse and register for events.');
      
      // Send email notification
      final emailSuccess = await EmailService.sendWelcomeEmail(user);
      
      // Send MongoDB notification to user
      final notificationSuccess = await MongoDBNotificationService.sendNotificationToUser(
        userId: user.id ?? '',
        title: 'Welcome to Eventura!',
        body: 'Welcome ${user.name}! Thank you for joining Eventura. You can now browse and register for events.',
        data: {
          'type': 'welcome',
          'userId': user.id ?? '',
          'userName': user.name,
        },
        type: 'welcome',
      );
      
      return emailSuccess && notificationSuccess;
    } catch (e) {
      debugPrint('Error sending welcome notification: $e');
      return false;
    }
  }

  /// Send account status change notification
  static Future<bool> sendAccountStatusNotification(User user, String newStatus) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Account Status Change');
      debugPrint('To: ${user.name} (${user.email})');
      debugPrint('Subject: Account Status Update');
      
      if (newStatus == 'blocked') {
        debugPrint('Content: Your account has been blocked. Please contact the administrator for assistance.');
      } else if (newStatus == 'active') {
        debugPrint('Content: Your account has been activated. You can now access all features.');
      }
      
      // Send email notification
      final emailSuccess = await EmailService.sendAccountStatusNotification(user, newStatus);
      
      // Send MongoDB notification to user
      final notificationSuccess = await MongoDBNotificationService.sendNotificationToUser(
        userId: user.id ?? '',
        title: 'Account Status Update',
        body: newStatus == 'blocked' 
          ? 'Your account has been blocked. Please contact the administrator for assistance.'
          : 'Your account has been activated. You can now access all features.',
        data: {
          'type': 'account_status',
          'userId': user.id ?? '',
          'userName': user.name,
          'newStatus': newStatus,
        },
        type: 'account_status',
      );
      
      return emailSuccess && notificationSuccess;
    } catch (e) {
      debugPrint('Error sending account status notification: $e');
      return false;
    }
  }

  /// Send bulk notification to all users (admin only)
  static Future<bool> sendBulkNotificationToUsers(String subject, String message, List<User> users) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Bulk Message');
      debugPrint('To: ${users.length} users');
      debugPrint('Subject: $subject');
      debugPrint('Content: $message');
      
      return await EmailService.sendBulkNotification(subject, message, users);
    } catch (e) {
      debugPrint('Error sending bulk notification: $e');
      return false;
    }
  }

  /// Send certificate generation notification
  static Future<bool> sendCertificateNotification(EventRegistration registration, Event event, String certificateUrl) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Certificate Generated');
      debugPrint('To: ${registration.userName} (${registration.userId})');
      debugPrint('Subject: Certificate of Attendance - ${event.title}');
      debugPrint('Content: Your certificate of attendance for "${event.title}" has been generated and is available for download.');
      debugPrint('Certificate URL: $certificateUrl');
      
      return await EmailService.sendEmail(
        to: registration.userEmail,
        subject: 'Certificate of Attendance - ${event.title}',
        htmlContent: '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>Certificate Generated</title>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #28a745; color: white; padding: 20px; text-align: center; }
              .content { padding: 20px; background-color: #f9f9f9; }
              .event-details { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🏆 Certificate Generated</h1>
              </div>
              <div class="content">
                <h2>Hello ${registration.userName}!</h2>
                <p>Your certificate of attendance for <strong>${event.title}</strong> has been generated.</p>
                
                <div class="event-details">
                  <h3>Event Details:</h3>
                  <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
                  <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
                  <p><strong>Location:</strong> ${event.location}</p>
                </div>
                
                <p>Your certificate is available for download in the app.</p>
                <p>Best regards,<br>The Eventura Team</p>
              </div>
              <div class="footer">
                <p>&copy; 2024 Eventura. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        ''',
      );
    } catch (e) {
      debugPrint('Error sending certificate notification: $e');
      return false;
    }
  }

  /// Send event capacity notification
  static Future<bool> sendEventCapacityNotification(Event event) async {
    try {
      debugPrint('📧 EMAIL NOTIFICATION: Event Capacity');
      debugPrint('To: Organizer ${event.organizerName}');
      debugPrint('Subject: Event Capacity Alert - ${event.title}');
      debugPrint('Content: Your event "${event.title}" is nearly full. Only ${event.availableSlots} slots remaining.');
      
      return await EmailService.sendEmail(
        to: 'organizer@eventura.com', // Replace with actual organizer email
        subject: 'Event Capacity Alert - ${event.title}',
        htmlContent: '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>Capacity Alert</title>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #ffc107; color: #333; padding: 20px; text-align: center; }
              .content { padding: 20px; background-color: #f9f9f9; }
              .event-details { background-color: white; padding: 15px; border-radius: 5px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>⚠️ Capacity Alert</h1>
              </div>
              <div class="content">
                <h2>Hello ${event.organizerName}!</h2>
                <p>Your event <strong>${event.title}</strong> is nearly full.</p>
                
                <div class="event-details">
                  <h3>Event Details:</h3>
                  <p><strong>Date:</strong> ${event.eventDate.toString().split(' ')[0]}</p>
                  <p><strong>Time:</strong> ${event.eventDate.toString().split(' ')[1].substring(0, 5)}</p>
                  <p><strong>Location:</strong> ${event.location}</p>
                  <p><strong>Total Slots:</strong> ${event.totalSlots}</p>
                  <p><strong>Available Slots:</strong> ${event.availableSlots}</p>
                </div>
                
                <p>Consider increasing capacity or closing registrations soon.</p>
                <p>Best regards,<br>The Eventura Team</p>
              </div>
              <div class="footer">
                <p>&copy; 2024 Eventura. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        ''',
      );
    } catch (e) {
      debugPrint('Error sending capacity notification: $e');
      return false;
    }
  }

  /// Get notification status for UI feedback
  static String getNotificationStatus(bool success, String type) {
    if (success) {
      return '✅ $type notification sent successfully';
    } else {
      return '❌ Failed to send $type notification';
    }
  }

  /// Simulate notification queue processing
  static Future<void> processNotificationQueue() async {
    debugPrint('📧 Processing notification queue...');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('📧 Notification queue processed successfully');
  }
} 