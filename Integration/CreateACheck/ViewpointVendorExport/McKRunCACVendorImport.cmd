@echo off
REM 2014.09.23 - LWO - Script created to allow for automated execution of Vendor Import.
REM To be run from C:\CAC11 directory on the applicable Viewpoint Application Server ( SETESTVIEWPOINT=DEV/Staging or MCKVIEWPOINT=Produciton)

CacImportCmd.exe import-to=vendors import-file="C:\CAC11\VP_CAC_Vendor_Export.csv" log-file="VP_CAC_Vendor_Import.log" first-line-is-hdr=true ow-mode=insertUpdate truncate-first=false email-user=BILLO

REM Delete Input file because of sensative information.
del /f "C:\CAC11\VP_CAC_Vendor_Export.csv"