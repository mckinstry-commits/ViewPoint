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
	Title:	SM Rate Template Effective Date (vSMRateTemplateEffectiveDateEffectiveDate)
	Created: 12/06/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: Effective date is for equipment, labor, material, and standard item override rates. 

Regarding, BASIS: Used in Billable Rate calculations for parts entered on a work order 
(in SM Work Orders, Work Completed tab).

A - Actual Cost = Uses actual cost of the part (i.e. the Cost Rate). 
S - Standard Cost = Uses the Std Unit Cost defined for the material in IN Location Material.
V - Average Cost = Uses the Avg Unit Cost defined for the material in IN Location Material. 
L - Last Cost = Uses the Last Unit Cost defined for the material in IN Location Material. 

NOTE:  The cost basis defined for a rate template is not used when the part entered on the work order
comes from a purchase order. Billable Rate calculations for purchased parts will always be based on 
the actual cost of the part from the PO.

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMRateTemplateEffectiveDate]
(@Co bCompany, @DefaultRateTemplate varchar(10), @InitialEffectiveDate datetime, @DeleteDataYN char(1))

AS 


/** BACKUP vSMRateTemplateEffectiveDate TABLE **/
IF OBJECT_ID('vSMRateTemplateEffectiveDate_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMRateTemplateEffectiveDate_bak
END;
BEGIN
	SELECT * INTO vSMRateTemplateEffectiveDate_bak FROM vSMRateTemplateEffectiveDate
END;


/** DELETE DATA IN vSMRateTemplateEffectiveDate TABLE **/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMRateTemplateEffectiveDate NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMRateTemplateEffectiveDate DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMRateTemplateEffectiveDate 
		WHERE SMCo=@Co
			AND RateTemplate<>@DefaultRateTemplate
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMRateTemplateEffectiveDate CHECK CONSTRAINT ALL;
	ALTER TABLE vSMRateTemplateEffectiveDate ENABLE TRIGGER ALL;
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMRateTemplateEffectiveDateID),0) FROM dbo.vSMRateTemplateEffectiveDate)


/** POPULATE SM Rate Template **/
SET IDENTITY_INSERT vSMRateTemplateEffectiveDate ON
ALTER TABLE vSMRateTemplateEffectiveDate NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMRateTemplateEffectiveDate DISABLE TRIGGER ALL;

INSERT vSMRateTemplateEffectiveDate
	(
			 SMRateTemplateEffectiveDateID
			,SMCo
			,RateTemplate
			,EffectiveDate
			,LaborRate
			,EquipmentMarkup
			,MaterialMarkupOrDiscount
			,MaterialBasis
			,MaterialPercent
			,SMRateOverrideID
			--,UniqueAttchID
			,Notes			

			--UD Fields
			--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	1
SELECT
			 SMRateTemplateEffectiveDateID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xrt.NewRateTemplate)
			,SMCo=@Co
			,RateTemplate=xrt.NewRateTemplate
			,EffectiveDate=@InitialEffectiveDate
			,LaborRate=MAX(CAST(LABORRATE AS NUMERIC(16,5))) --MAY NEED TO CHANGE TO AVG IF GROUPING
			,EquipmentMarkup=0 --MOT AVAILABLE IN STO
			,MaterialMarkupOrDiscount='M' --M or D
			,MaterialBasis='A' --Average Cost (See Notes above.)
			,MaterialPercent=MAX(rs.STOCKPARTSMARKUP)
			,SMRateOverrideID=NULL
			,Notes=NULL

			--,UniqueAttchID
			--UD Fields
			--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=1
--SELECT xrt.SMCo, xrt.NewRateTemplate
--SELECT *
FROM CV_TL_Source_SM.dbo.RATESHEET rs
INNER JOIN bHQCO co
	ON HQCo=@Co
INNER JOIN budXRefSMRateTemplate xrt
	ON xrt.SMCo=@Co AND xrt.OldRateTemplate=rs.RATESHEETNBR
LEFT JOIN vSMRateTemplateEffectiveDate vrt
	ON vrt.SMCo=@Co AND vrt.RateTemplate=xrt.NewRateTemplate
WHERE vrt.RateTemplate IS NULL 
GROUP BY xrt.SMCo, xrt.NewRateTemplate
ORDER BY xrt.SMCo, xrt.NewRateTemplate;

SET IDENTITY_INSERT vSMRateTemplateEffectiveDate OFF
ALTER TABLE vSMRateTemplateEffectiveDate CHECK CONSTRAINT ALL;
ALTER TABLE vSMRateTemplateEffectiveDate ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMRateTemplateEffectiveDate where SMCo=@Co;
select * from vSMRateTemplateEffectiveDate where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMRateTemplate where SMCo=@Co;
select * from vSMRateTemplateEffectiveDate where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.RATESHEET
**/
GO
