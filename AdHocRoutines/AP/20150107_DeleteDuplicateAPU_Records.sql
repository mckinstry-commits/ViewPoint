--/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT 
--	CollectedInvoiceNumber, CollectedInvoiceDate, CollectedInvoiceAmount, count(*)
--  FROM [MCK_INTEGRATION].[dbo].[RLB_AP_ImportData_New] WHERE MetaFileName LIKE '%20141229%' AND CollectedInvoiceNumber='45179'
--  GROUP BY CollectedInvoiceNumber, CollectedInvoiceDate, CollectedInvoiceAmount
--  ORDER BY CollectedInvoiceNumber

SELECT * INTO HQAI_20150107_LWO FROM HQAI
SELECT * INTO HQAT_20150107_LWO FROM HQAT
SELECT * INTO APUL_20150107_LWO FROM APUL
SELECT * INTO APUI_20150107_LWO FROM APUI
SELECT * INTO APUR_20150107_LWO FROM APUR

 --HQAI Attachments
SELECT * FROM HQAI WHERE AttachmentID IN ( SELECT DISTINCT t2.AttachmentID FROM 
(
SELECT DISTINCT AttachmentID FROM HQAT WHERE UniqueAttchID IN (SELECT DISTINCT t1.UniqueAttchID FROM 
(
	SELECT apui.UniqueAttchID,apui.APCo, apui.UIMth, apui.UISeq, apui.VendorGroup, apui.Vendor, apui.APRef, apui.InvDate, InvTotal FROM APUI apui
	WHERE CHECKSUM(APRef, InvDate, InvTotal) IN 
		(
		SELECT distinct
		CHECKSUM( CollectedInvoiceNumber, CollectedInvoiceDate, CollectedInvoiceAmount)
		from 
		[MCK_INTEGRATION].[dbo].[RLB_AP_ImportData_New] WHERE MetaFileName LIKE '%20141229%'
		)
) t1 ) ) t2 ) 


--HQAT Attachments
SELECT * FROM HQAT WHERE UniqueAttchID IN (SELECT DISTINCT t1.UniqueAttchID FROM 
(
	SELECT apui.UniqueAttchID,apui.APCo, apui.UIMth, apui.UISeq, apui.VendorGroup, apui.Vendor, apui.APRef, apui.InvDate, InvTotal FROM APUI apui
	WHERE CHECKSUM(APRef, InvDate, InvTotal) IN 
		(
		SELECT distinct
		CHECKSUM( CollectedInvoiceNumber, CollectedInvoiceDate, CollectedInvoiceAmount)
		from 
		[MCK_INTEGRATION].[dbo].[RLB_AP_ImportData_New] WHERE MetaFileName LIKE '%20141229%'
		)
) t1 )

--APUR Header Review
SELECT * FROM APUR apur join
(
SELECT apui.APCo, apui.UIMth, apui.UISeq, apui.VendorGroup, apui.Vendor, apui.APRef, apui.InvDate, InvTotal FROM APUI apui
WHERE CHECKSUM(APRef, InvDate, InvTotal) IN 
	(
	SELECT distinct
	CHECKSUM( CollectedInvoiceNumber, CollectedInvoiceDate, CollectedInvoiceAmount)
	from 
	[MCK_INTEGRATION].[dbo].[RLB_AP_ImportData_New] WHERE MetaFileName LIKE '%20141229%'
	)
) t1 ON
apur.APCo=t1.APCo
AND apur.UIMth=t1.UIMth
AND apur.UISeq=t1.UISeq

-- APUL Lines
SELECT * FROM APUL apul join
(
SELECT apui.APCo, apui.UIMth, apui.UISeq, apui.VendorGroup, apui.Vendor, apui.APRef, apui.InvDate, InvTotal FROM APUI apui
WHERE CHECKSUM(APRef, InvDate, InvTotal) IN 
	(
	SELECT distinct
	CHECKSUM( CollectedInvoiceNumber, CollectedInvoiceDate, CollectedInvoiceAmount)
	from 
	[MCK_INTEGRATION].[dbo].[RLB_AP_ImportData_New] WHERE MetaFileName LIKE '%20141229%'
	)
) t1 ON
apul.APCo=t1.APCo
AND apul.UIMth=t1.UIMth
AND apul.UISeq=t1.UISeq
--ORDER BY APCo, UIMth, UISeq,APRef

--APUI Header
SELECT apui.APCo, apui.UIMth, apui.UISeq, apui.VendorGroup, apui.Vendor, apui.APRef, apui.InvDate, InvTotal FROM APUI apui
WHERE CHECKSUM(APRef, InvDate, InvTotal) IN 
	(
	SELECT distinct
	CHECKSUM( CollectedInvoiceNumber, CollectedInvoiceDate, CollectedInvoiceAmount)
	from 
	[MCK_INTEGRATION].[dbo].[RLB_AP_ImportData_New] WHERE MetaFileName LIKE '%20141229%'
	)

--SELECT tmp.MetaFileName,* 
--FROM
-- APUL apul JOIN dbo.APUI apui ON apul.APCo=apui.APCo AND apul.UIMth=apui.UIMth AND apul.UISeq=apui.UISeq JOIN
-- [MCK_INTEGRATION].[dbo].[RLB_AP_ImportData_New] tmp ON
-- CHECKSUM(apui.APRef, apui.InvDate, apui.InvTotal)=CHECKSUM( tmp.CollectedInvoiceNumber, tmp.CollectedInvoiceDate, tmp.CollectedInvoiceAmount)
--WHERE apul.SMPhase IS NOT NULL
----AND tmp.MetaFileName LIKE '%20141230%'
--ORDER BY tmp.Created desc