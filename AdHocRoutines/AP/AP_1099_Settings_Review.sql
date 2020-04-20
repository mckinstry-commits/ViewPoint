--Update AP Transactions with valid 1099 information
--1. Review and validate APVM values first.
--2. Update APTH/APTD with values from APVM
SELECT VendorGroup, Vendor, Name AS VendorName, V1099YN, V1099Type, V1099Box, V1099AddressSeq FROM APVM WHERE VendorGroup <100 AND V1099YN='Y'

SELECT apvm.VendorGroup, apvm.Vendor, Name AS VendorName, apvm.V1099YN AS VendorV1099YN, apvm.V1099Type AS VendorV1099Type, apvm.V1099Box AS VendorV1099Box, apvm.V1099AddressSeq AS VendorV1099AddressSeq, apth.APRef, apth.InvDate, apth.InvTotal, apth.V1099YN AS APTranV1099YN, apth.V1099Type AS APTranV1099Type, apth.V1099Box AS APTranV1099Box
FROM APTH apth JOIN APVM apvm ON apth.VendorGroup=apvm.VendorGroup AND apth.Vendor=apvm.Vendor WHERE apth.VendorGroup <100 and apth.V1099YN='Y'
