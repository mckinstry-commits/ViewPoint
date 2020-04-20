SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	Convert STO SM Customers via AR to VP SM Customer (vSMCustomer)	
	Created: 11/21/2012
	Created by:	VCS - Technical Services - Brenda Ackerson
	Revisions:	
		1. 11/26/2012 BBA - Added ability to set the SMCustomerID field.
		2. 12/03/2012 BBA - Added update for new SMCustomer column on the budXRefCustomer
			table. And, added budXRefCustomer to join and add criteria to convert only
			SM Customers with that are ARCUST on the SM INVOICE table. 
		3. 01/17/2013 BBA - Modified code under UPDATE SMCustomerYN COLUMN section as 
			needed to include the SERVICESITE table which has more customers that may
			not have been invoiced yet.
		4. 04/15/2013 BBA - The Status in AR Customers and Active column in SM Customers 
			are not the same. Active is Y/N and Status is A/I Active or Inactive. Corrected code.
			
	IMPORTANT: 
		
**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMCustomer] 
(@Co bCompany,@DefaultRateTemplate varchar(10),@DeleteDataYN char(1))
 
AS 


/** DECLARE AND SET PARAMETERS **/
DECLARE @CustGroup tinyint	
SET @CustGroup=(SELECT CustGroup FROM bHQCO WHERE HQCo=@Co)

DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMCustomerID),0) FROM dbo.vSMCustomer)


/** BACKUP DATA IN vSMCustomer TABLE **/
IF OBJECT_ID('vSMCustomer_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMCustomer_bak
END;
BEGIN
	SELECT * INTO vSMCustomer_bak FROM vSMCustomer
END;


/** DELETE DATA IN vSMServiceSite TABLE **/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMCustomer NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMCustomer DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMCustomer
		WHERE vSMCustomer.CustGroup=@CustGroup
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';
	ALTER TABLE vSMCustomer CHECK CONSTRAINT ALL;	
	ALTER TABLE vSMCustomer ENABLE TRIGGER ALL;
END;


--/** UPDATE SMCustomerYN COLUMN ON UD CROSS REFERENCE: AR CUSTOMERS **/
----declare @CustGroup bGroup set @CustGroup=1
--IF OBJECT_ID('#SMCUSTOMERS_TEMP') IS NOT NULL
--BEGIN
--	DROP TABLE #SMCUSTOMERS_TEMP
--END;

--BEGIN	
--	SELECT CustGroup=@CustGroup, Customer/*ARCUST*/, SMCustomer='Y'
--	INTO #SMCUSTOMERS_TEMP 
--	--FROM CV_TL_Source_SM.dbo.INVOICE smi
--	FROM Viewpoint.dbo.bARCM smi
--	INNER JOIN Viewpoint.dbo.budxrefARCustomer xc
--		ON xc.CustGroup=@CustGroup AND xc.OldCustomerID=smi.Customer--smi.ARCUST
--	GROUP BY smi.Customer/*smi.ARCUST*/
--	ORDER BY smi.Customer/*smi.ARCUST*/;

--	INSERT #SMCUSTOMERS_TEMP (CustGroup,ARCUST,SMCustomer)
--	SELECT CustGroup=@CustGroup, ARCUST, SMCustomer='Y'
--	FROM CV_TL_Source_SM.dbo.SERVICESITE ss
--	INNER JOIN budxrefARCustomer xc
--		ON xc.CustGroup=@CustGroup AND xc.OldCustomerID=ss.ARCUST
--	GROUP BY ss.ARCUST
--	ORDER BY ss.ARCUST;
--END;

--IF OBJECT_ID('#SMCUSTOMERS') IS NOT NULL
--BEGIN
--	DROP TABLE #SMCUSTOMERS
--END;

--SELECT DISTINCT CustGroup, ARCUST, SMCustomer
--INTO #SMCUSTOMERS
--FROM #SMCUSTOMERS_TEMP 
--ORDER BY ARCUST

----SELECT * FROM #SMCUSTOMERS ORDER BY ARCUST

--/** Update budXRefCustomer SMCustomerYN Column**/
----declare @CustGroup bGroup set @CustGroup=1
--UPDATE budxrefARCustomer
--SET SMCustomerYN='Y'
--FROM budxrefARCustomer xc
--INNER JOIN #SMCUSTOMERS sm
--	ON sm.CustGroup=@CustGroup AND sm.ARCUST=xc.OldCustomerID;


/** Convert AR Customers to SM Customers **/
SET IDENTITY_INSERT vSMCustomer ON
ALTER TABLE vSMCustomer NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMCustomer DISABLE TRIGGER ALL;

INSERT INTO dbo.vSMCustomer
		(
			SMCustomerID
           ,SMCo
           ,CustGroup
           ,Customer
           ,Active
           --,UniqueAttchID
           ,Notes
           ,RateTemplate
           ,BillToARCustomer
           ,ReportID
           ,SMRateOverrideID
           ,SMStandardItemDefaultID
           ,CustomerPOSetting
           ,PrimaryTechnician
           ,InvoiceGrouping
           ,InvoiceSummaryLevel
           ,udConvertedYN
		)

SELECT		SMCustomerID=@MAXID+ROW_NUMBER() OVER (ORDER BY @CustGroup, ar.Customer)
		   ,SMCo=@Co
           ,CustGroup=@CustGroup
           ,Customer=ar.Customer
           ,Active=-- (ARCM.Status varchar: A = Active)(SMCustomer = bYN)
				CASE
					WHEN ar.Status='A' THEN 'Y'
					ELSE 'N'
				END 
           --,UniqueAttchID
           ,Notes=ar.Notes
           ,RateTemplate=@DefaultRateTemplate --Setup Standard Rate Template
           ,BillToARCustomer=ar.Customer
           ,ReportID=NULL
           ,SMRateOverrideID=NULL
           ,SMStandardItemDefaultID=NULL
           ,CustomerPOSetting='N' --N=Non Required, R=Required
           ,PrimaryTechnician=NULL
           ,InvoiceGrouping='C' --C=One Per Customer,S=One per Service Site,W=One per Work Order
           ,InvoiceSummaryLevel='L' --L=Line Type,C=Cost Type,T=Transaction 
           ,udConvertedYN='Y'
      
--declare @CustGroup bGroup set @CustGroup=
--select *
FROM bARCM ar
INNER JOIN Viewpoint.dbo.budxrefARCustomer xc
	ON xc.CustGroup=@CustGroup AND xc.NewCustomerID=ar.Customer
LEFT JOIN vSMCustomer sm
	ON sm.CustGroup=ar.CustGroup AND sm.Customer=ar.Customer
WHERE ar.CustGroup=@CustGroup AND xc.SMCustomer='Y'
	AND sm.Customer IS NULL 
ORDER BY ar.CustGroup, ar.Customer; 

SET IDENTITY_INSERT vSMCustomer OFF
ALTER TABLE vSMCustomer CHECK CONSTRAINT ALL;
ALTER TABLE vSMCustomer ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @CustGroup bGroup set @CustGroup=1
select COUNT(*) as vSMCustomer_Count from vSMCustomer where CustGroup=@CustGroup;
select * from vSMCustomer where CustGroup=@CustGroup;

SELECT COUNT(*) as bARCM_Customer_Count 
FROM bARCM ar
INNER JOIN Viewpoint.dbo.budxrefARCustomer xc
	ON xc.CustGroup=@CustGroup AND xc.NewCustomerID=ar.Customer;

SELECT * FROM bARCM ar
INNER JOIN Viewpoint.dbo.budxrefARCustomer xc
	ON xc.CustGroup=@CustGroup AND xc.NewCustomerID=ar.Customer;


/** DATA REVIEW **/
/*
select * from dbo.vSMRateTemplate
select * from dbo.vSMRateOverride
select * from dbo.vSMStandardItemDefault
select * from dbo.vSMCustomer
*/

GO
