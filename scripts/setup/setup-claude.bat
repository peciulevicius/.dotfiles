@echo off
powershell -ExecutionPolicy RemoteSigned -File "%~dp0setup-claude.ps1" %*
