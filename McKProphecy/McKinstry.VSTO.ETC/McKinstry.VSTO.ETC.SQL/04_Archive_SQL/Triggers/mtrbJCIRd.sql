USE Viewpoint
GO
/****** Object:  Trigger [dbo].[btJCIDi]    Script Date: 5/9/2016 9:08:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[mtrbJCIRd] on [dbo].[bJCIR] 
FOR DELETE
AS

	DECLARE @errmsg varchar(255), @numrows int
    
    SELECT @numrows = @@rowcount
    if @numrows = 0 return
    SET nocount on


-- ========================================================================
-- DELETE TRIGGER on bJCID
-- Author:		Ziebell, Jonathan
-- Create date: 05/06/2016
-- Description:	When Batch activity completed that deletes a JCIR Row, delete any matching detail rows from budJCIRD 
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================


BEGIN

--DELETE FROM budJCIRD
--Check for existing Revenue Project Detail Rows for the current Month, If old rows for current month found, Delete them. 
DELETE FROM budJCIRD 
WHERE EXISTS (SELECT 1 FROM deleted del 
				WHERE del.Co = budJCIRD.Co 
				AND del.BatchId = budJCIRD.BatchId
				AND del.BatchSeq = budJCIRD.BatchSeq
				AND del.Contract = budJCIRD.Contract 
				AND del.Item = budJCIRD.Item 
				AND del.Mth = budJCIRD.Mth) 

END

RETURN