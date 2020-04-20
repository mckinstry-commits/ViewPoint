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
	Title:	SM Pay Type (vSMPayType)
	Created: 05/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 11/21/2012 BBA - Revised to use the new SM Pay Types cross reference and 
			added group by for consolidation purposes.
		2. 11/26/2012 BBA - Added disable and enable trigger commands.

Notes: @UseSMPTDescYN means do you want to use the SM Pay Type description or
the associated Earn Code description from the UD Cross Reference tables.

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMPayType]
(@Co bCompany, @UseSMPTDescYN char(1), @DeleteDataYN char(1))

AS 


/** BACKUP vSMPayType TABLE **/
IF OBJECT_ID('vSMPayType_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMPayType_bak
END;
BEGIN
	SELECT * INTO vSMPayType_bak FROM vSMPayType
END;


/**DELETE DATA IN vSMPayType TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMPayType NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMPayType DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMPayType WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMPayType CHECK CONSTRAINT ALL;
	ALTER TABLE vSMPayType ENABLE TRIGGER ALL;	
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMPayTypeID),0) FROM dbo.vSMPayType)


/** POPULATE SM Pay Types **/
SET IDENTITY_INSERT vSMPayType ON
ALTER TABLE vSMPayType NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMPayType DISABLE TRIGGER ALL;

INSERT vSMPayType
	(
			 SMPayTypeID
			,SMCo
			,PayType
			,Description
			,CostMethod
			,Factor
			,Active
			,Notes
			,EarnCode
			--,UniqueAttchID
			--UD Fields
			--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	1
SELECT
			 SMPayTypeID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xpt.NewPayType)
			,SMCo=@Co
			,PayType=xpt.NewPayType
			,Description=MAX(
				case 
					when @UseSMPTDescYN IN('Y','y') then xpt.NewDescription
					else xec.NewDescription
				end)
			,CostMethod=MAX( 
				case --0-Multiplier or 1-Dollar Rate	
					when COSTMULTIPLIER=0 and SALEMULTIPLIER=0 then 1
					else 0
				end)				
			,Factor=MAX(
				case 
					when COSTMULTIPLIER<>0 and SALEMULTIPLIER=0 then COSTMULTIPLIER  
					when COSTMULTIPLIER=0 and SALEMULTIPLIER<>0 then SALEMULTIPLIER  
					when COSTMULTIPLIER=0 and SALEMULTIPLIER=0 and UNITCOST<>0 AND UNITSALE=0	
						then UNITCOST
					else UNITSALE
				end)				
			,Active=MAX(xpt.ActiveYN)
			,Notes=NULL
			,EarnCode=MAX(xpt.NewEarnCode)
			--,UniqueAttchID
			--UD Fields
			--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.PAYTYPE spt
LEFT JOIN budXRefSMPayTypes xpt
	ON xpt.SMCo=@Co AND xpt.OldPayType=spt.PAYTYPENBR
LEFT JOIN budXRefPREarnCodes xec
	ON xec.PRCo=@Co AND xec.NewEarnCode=xpt.NewEarnCode
LEFT JOIN vSMPayType vpt
	ON vpt.SMCo=@Co AND vpt.PayType=xpt.NewPayType
WHERE vpt.PayType IS NULL 
GROUP BY xpt.SMCo, xpt.NewPayType
ORDER BY xpt.SMCo, xpt.NewPayType;

SET IDENTITY_INSERT vSMPayType OFF
ALTER TABLE vSMPayType CHECK CONSTRAINT ALL;
ALTER TABLE vSMPayType ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMPayType where SMCo=@Co;
select * from vSMPayType where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMPayType where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.PAYTYPE

select distinct PRPAYID from CV_TL_Source_SM.dbo.PAYTYPE order by PRPAYID;
select distinct cast(PRPAYID as int) from CV_TL_Source_SM.dbo.PAYTYPE order by cast(PRPAYID as int);
**/
GO
