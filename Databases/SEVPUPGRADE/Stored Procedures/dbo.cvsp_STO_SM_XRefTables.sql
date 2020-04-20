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
	Title:	Execute SM Cross Reference Tables Procedures
	Created: 02/01/2013
	Created by:	VCS Technical Services - Brenda Ackerson
	Revisions:	
		1. 

IMPORTANT: Use to populate all UD SM Cross Reference tables. If the @DeleteDataYN
parameter is set to Y or y, then it will delete all data in each cross reference table;
otherwise it will only append new data. May need to run procedures separately if
only some tables need data deleted and repopulated.

IMPORTANT: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefTables] 
(@Co TINYINT, @UseScopeDescriptionYN CHAR(1)
,@RefreshVendorNameYN CHAR(1), @UseVendorStartNoYN CHAR(1), @VendorStartNo INT
,@DeleteDataYN CHAR(1))

AS 

/** DECLARE AND SET PARAMETERS **/
DECLARE @VendorGroup bGroup 
SET @VendorGroup=(SELECT VendorGroup FROM bHQCO WHERE HQCo=@Co)


/** UPDATE UD SM CROSS REFERENCE TABLES **/

--EXEC dbo.cvsp_STO_SM_XRefAPVendor @Co, @RefreshVendorNameYN, @UseVendorStartNoYN, @VendorStartNo;

EXEC dbo.cvsp_STO_SM_XRefSMAgrTypes @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMCallTypes @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMClass @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMCostTypes @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMDept @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMEQPTypes @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMLaborCodes @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMPayTypes @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMRateTemplate @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMStdItems @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMStdTasks @Co, @DeleteDataYN;
EXEC dbo.cvsp_STO_SM_XRefSMWorkScopes @Co, @UseScopeDescriptionYN, @DeleteDataYN;

GO
