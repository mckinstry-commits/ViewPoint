SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2013 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	SM Work Order (vSMWorkOrder)
	Created: 02/15/2013
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: Initially designed to create a SQL Table to create a delimited file to use the 
SM Import Templates.

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMWorkOrder_IM]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMWorkOrder TABLE **/
IF OBJECT_ID('vSMWorkOrder_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMWorkOrder_bak
END;
BEGIN
	SELECT * INTO vSMWorkOrder_bak FROM vSMWorkOrder
END;


/**DELETE DATA IN vSMWorkOrder TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	DELETE vSMWorkOrder WHERE SMCo=@Co
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMWorkOrderID),0) FROM dbo.vSMWorkOrder_IM)


/** POPULATE SM Technicians **/
SET IDENTITY_INSERT vSMWorkOrder_IM ON
--ALTER TABLE vSMWorkOrder NOCHECK CONSTRAINT ALL;
--ALTER TABLE vSMWorkOrder DISABLE TRIGGER ALL;

INSERT INTO vSMWorkOrder_IM
	(
			SMWorkOrderID
		   ,SMCo
           ,WorkOrder
           ,CustGroup
           ,Customer
           ,ServiceSite
           ,Description
           ,ServiceCenter
           ,RequestedDate
           ,RequestedTime
           ,EnteredDateTime
           ,EnteredBy
           ,RequestedBy
           ,ContactName
           ,ContactPhone
           ,IsNew
           ,Notes
           --,UniqueAttchID
           ,WOStatus
           ,LeadTechnician
           ,RequestedByPhone
           ,JCCo
           ,Job
           ,CostingMethod
	)
	
SELECT    
			SMWorkOrderID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, wo.WRKORDNBR)
           ,SMCo=@Co
           ,WorkOrder=wo.WRKORDNBR
           ,CustGroup=co.CustGroup
           ,Customer=xar.NewCustomerID
           ,ServiceSite=CAST(wo.SERVSITENBR AS VARCHAR(20))
           ,Description=wo.COMMENTS
           ,ServiceCenter=ctr.ABBREVIATION --Both are varchar(10)
           ,RequestedDate=wo.CALLDATE
           ,RequestedTime=wo.CALLTIME
           ,EnteredDateTime=wo.DATEENTER
           ,EnteredBy= --Foreign Key DataType=bVPUserName 
					ISNULL(up.VPUserName,'viewpointcs')
           ,RequestedBy=wo.NAME
           ,ContactName=wo.CONTACT
           ,ContactPhone=NULL
           ,IsNew= --0=N, 1=Y
                CASE 
					WHEN DATECOMPLETE IS NOT NULL THEN 0
					ELSE 1
				END
           ,Notes=NULL
           --,UniqueAttchID
           ,WOStatus= --0=Open; 1-Complete
				--Need to get info on STATUS values
           		CASE 
					WHEN wo.STATUS = 0 THEN 0
					WHEN wo.STATUS = 1 THEN 1
					WHEN wo.STATUS = 2 THEN 1
					WHEN wo.STATUS = 3 THEN 1
					WHEN wo.STATUS = 4 THEN 1														
					WHEN wo.STATUS = 5 THEN 1
					WHEN wo.STATUS = 6 THEN 1
					WHEN wo.STATUS = 7 THEN 1										
					ELSE 0
				END
           ,LeadTechnician=xt.VPEmployee
           ,RequestedByPhone=NULL
           ,JCCo=@Co
           ,Job=xjc.NewJob
           ,CostingMethod= --Cost, Revenue, NULL
			--Need to determine what method
				CASE 
					WHEN 1=1 THEN 'Cost'
					WHEN 1<>1 THEN 'Revenue'
					ELSE NULL
				END
		
--DECLARE @Co bCompany SET @Co=1         
--SELECT *
FROM CV_TL_Source_SM.dbo.WRKORDER wo
INNER JOIN CV_TL_Source_SM.dbo.CENTER ctr
	ON ctr.CENTERNBR=wo.CENTERNBR
INNER JOIN bHQCO co
	ON co.HQCo=@Co
INNER JOIN budXRefCustomer xar
	ON xar.CustGroup=co.CustGroup AND xar.OldCustomerID=wo.ARCUST
INNER JOIN budXRefSMTechnician xt
	ON xt.SMCo=co.HQCo AND xt.SMTechnician=wo.TECHNICIAN
LEFT JOIN budXRefJCAllJobs xjc
	ON xjc.JCCo=co.HQCo AND xjc.OldJob=wo.JCJOB	
LEFT JOIN vDDUP up
	ON up.VPUserName=LOWER(wo.ENTERBY)	

SET IDENTITY_INSERT vSMWorkOrder_IM OFF
--ALTER TABLE vSMWorkOrder CHECK CONSTRAINT ALL;
--ALTER TABLE vSMWorkOrder ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--DECLARE @Co bCompany SET @Co=
SELECT COUNT(*) FROM vSMWorkOrder_IM WHERE SMCo=@Co; --(87254 row(s) affected)
SELECT * FROM vSMWorkOrder_IM WHERE SMCo=@Co;


/** DATA REVIEW 
--DECLARE @Co bCompany SET @Co=
SELECT * FROM vSMWorkOrder_IM where SMCo=@Co;

SELECT * FROM CV_TL_Source_SM.dbo.WRKORDER;
SELECT DISTINCT JCJOB FROM CV_TL_Source_SM.dbo.WRKORDER;
SELECT DISTINCT STATUS FROM CV_TL_Source_SM.dbo.WRKORDER;
SELECT DISTINCT JCCOSTING FROM CV_TL_Source_SM.dbo.WRKORDER;
**/
GO
