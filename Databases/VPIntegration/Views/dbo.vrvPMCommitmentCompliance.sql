SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   
CREATE  view [dbo].[vrvPMCommitmentCompliance]
    
/**************************************************************************************
Created:		6/24/2011 HH - TK-05764

Description:	Lists all Compliance Codes for POs/SLs in one view 
				
				     
 Usage:			Used by the PM Vendor Register Drilldown report (Compliance Drilldown)

**************************************************************************************/

AS

WITH CommitmentCompliance (Co, DocType, DocID, CompCode, Seq, [Description], ExpDate, Verify, Complied)
AS
(
SELECT POCo, 'PO', PO, CompCode, Seq, [Description], ExpDate, Verify, Complied
FROM POCT

UNION ALL 

SELECT SLCo, 'SL', SL, CompCode, Seq, [Description], ExpDate, Verify, Complied
FROM SLCT
)
SELECT * FROM CommitmentCompliance

GO
GRANT SELECT ON  [dbo].[vrvPMCommitmentCompliance] TO [public]
GRANT INSERT ON  [dbo].[vrvPMCommitmentCompliance] TO [public]
GRANT DELETE ON  [dbo].[vrvPMCommitmentCompliance] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMCommitmentCompliance] TO [public]
GO
