@echo off
powershell -ExecutionPolicy RemoteSigned -File "%~dp0update.ps1" %*
