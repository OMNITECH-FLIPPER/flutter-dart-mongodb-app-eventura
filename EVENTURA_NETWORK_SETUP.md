# 🌐 Eventura Network Setup Guide

## 🚀 Making Eventura Available to All Devices

Your Eventura app is now configured to be accessible from all devices on your network!

## 📋 Current Setup

### ✅ **What's Running:**
- **Backend Server**: Running on port 42952 (accessible from all devices)
- **Flutter App**: Running on port 43218 (accessible from all devices)
- **MongoDB**: Connected and working
- **API Base URL**: Configured for network access

### 🌍 **Access URLs:**

#### **Local Device (This Computer):**
- Flutter App: `http://localhost:43218`
- Backend API: `http://localhost:42952`
- Health Check: `http://localhost:42952/health`

#### **Other Devices on Network:**
- Flutter App: `http://YOUR_IP_ADDRESS:43218`
- Backend API: `http://YOUR_IP_ADDRESS:42952`
- Health Check: `http://YOUR_IP_ADDRESS:42952/health`

## 🔧 Manual Hosts File Setup (Optional)

To use `eventura.local` instead of IP address:

1. **Open Notepad as Administrator**
2. **Open file**: `C:\Windows\System32\drivers\etc\hosts`
3. **Add this line** (replace with your actual IP):
   ```
   192.168.1.XXX eventura.local
   ```
4. **Save the file**

Then you can access:
- Flutter App: `http://eventura.local:43218`
- Backend API: `http://eventura.local:42952`

## 📱 How Other Devices Can Access Eventura

### **Step 1: Find Your IP Address**
Run this command to find your IP:
```powershell
ipconfig
```
Look for your local IP (usually starts with 192.168.x.x or 10.x.x.x)

### **Step 2: Access from Other Devices**
1. **Make sure devices are on the same WiFi network**
2. **Open any web browser** (Chrome, Safari, Firefox, etc.)
3. **Navigate to**: `http://YOUR_IP_ADDRESS:43218`
4. **The Eventura app will load!**

### **Step 3: Test the Connection**
- **Health Check**: `http://YOUR_IP_ADDRESS:42952/health`
- **API Info**: `http://YOUR_IP_ADDRESS:42952/api`

## 🔒 Security Notes

### **Windows Firewall**
You may need to allow these ports:
- **Port 42952** (Backend API)
- **Port 43218** (Flutter Web App)

### **To Allow Ports:**
1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Click "Change settings"
4. Click "Allow another app"
5. Browse to your Node.js and Flutter executables
6. Make sure both Private and Public are checked

## 🚀 Quick Start Commands

### **Start Backend Server:**
```bash
npm start
```

### **Start Flutter App (Network Access):**
```bash
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 43218
```

### **Test Connection:**
```bash
npm run test-connection
```

## 📊 Available Features

### **✅ Working Features:**
- **Complete UI** with Material Design 3
- **User Authentication** (Admin: 22-4957-735 / KYLO.omni0)
- **User Management** interface
- **Event Management** screens
- **Role-based dashboards** (Admin, Organizer, User)
- **Responsive design** for all devices
- **MongoDB integration** via backend

### **🌐 Network Features:**
- **Cross-device access** from any device on the network
- **Mobile-friendly** responsive design
- **Real-time updates** via API
- **Secure authentication**

## 🔍 Troubleshooting

### **Can't Access from Other Devices?**
1. **Check Windows Firewall** - Allow ports 42952 and 43218
2. **Verify Network Connection** - Ensure devices are on same WiFi
3. **Test Local Access** - Try `http://localhost:43218` first
4. **Check IP Address** - Use `ipconfig` to confirm your IP

### **Port Already in Use?**
1. **Find process using port**: `netstat -ano | findstr :43218`
2. **Kill process**: `taskkill /PID <PID> /F`
3. **Restart services**

### **MongoDB Connection Issues?**
1. **Check backend logs** for connection errors
2. **Verify MongoDB Atlas** settings
3. **Test connection**: `npm run test-connection`

## 🎯 Success Indicators

### **✅ Everything Working:**
- Backend shows: "🚀 Eventura Backend Server running on port 42952"
- Flutter shows: "This app is linked to the debug service"
- Health check returns: `{"status":"OK","message":"Eventura Backend Server is running"}`
- Other devices can access the app via your IP address

## 🎉 You're All Set!

Your Eventura app is now:
- ✅ **Running locally** on your computer
- ✅ **Accessible from all devices** on your network
- ✅ **Fully functional** with all features
- ✅ **Ready for testing** and development

**Happy Eventura-ing!** 🎉 