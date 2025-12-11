# Injecter - Android Payload Injection Tool

![Injecter Banner](https://img.shields.io/badge/Injecter-Android%20Payload%20Tool-red)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Termux-blue)
![License](https://img.shields.io/badge/License-MIT-green)

A simple bash tool to create Android meterpreter payloads .

## Features
- Create signed Android APK payloads
- Automatic dependency checking
- Simple IP/port configuration
- Generate Metasploit listener commands
- Clean and user-friendly interface

## Requirements
- Linux (Kali, Ubuntu, etc.) or Termux
- Metasploit Framework
- Java JDK (for signing APKs)

## Installation

### Method 1: Direct Download
```bash
git clone https://github.com/yourusername/Injecter.git
cd Injecter
chmod +x setup.sh Inject.sh
./setup.sh
