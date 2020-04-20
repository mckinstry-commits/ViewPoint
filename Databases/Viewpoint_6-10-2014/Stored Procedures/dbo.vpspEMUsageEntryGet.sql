SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tom Jochums
-- Create date: 2/26/10
-- Modified: Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
-- Description:	Retrieves EM Usage Posting entries for the given batch that a VC User is able to access
-- =============================================
CREATE PROCEDURE [dbo].[vpspEMUsageEntryGet]
	@Key_EMCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @VPUserName AS bVPUserName, @Key_Seq_BatchSeq AS INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	Declare @EMGroup As tinyint

    SELECT EMBF.Mth As Key_Mth
        , EMBF.BatchId As Key_BatchId
        , CONVERT(VARCHAR, EMBF.BatchSeq) AS Key_BatchSequence
        , EMBF.Equipment As EquipmentId
        , EMEM.[Description] As EquipmentDescription
        , EMBF.EMGroup As EMGroup
        , EMBF.PhaseGrp As PhaseGroup
        , EMBF.JCPhase As Phase
        , JCJP.[Description] As PhaseDescription
        , EMBF.JCCostType
        , JCCT.[Description] As Abbreviation
        , EMBF.CurrentOdometer
        , EMBF.CurrentHourMeter
        , EMBF.RevTimeUnits
        , EMBF.[Description] AS Notes
        , EMBF.Job
        , JCJM.[Description] As JobDescription
        , EMBF.JCCo As JCCo
        , EMBF.Co As Key_EMCo
        , @VPUserName As VPUserName
        , EMBF.ActualDate As [Date]
        , EMBF.KeyID
     FROM EMBF
LEFT JOIN JCJP 
       ON EMBF.Job = JCJP.Job
      AND EMBF.JCCo = JCJP.JCCo
      AND EMBF.PhaseGrp = JCJP.PhaseGroup 
      AND EMBF.JCPhase = JCJP.Phase
LEFT JOIN JCCT 
       ON EMBF.JCCostType = JCCT.CostType 
      AND EMBF.PhaseGrp = JCCT.PhaseGroup
LEFT JOIN EMEM
       ON EMBF.JCCo = EMEM.EMCo
      AND EMBF.Equipment = EMEM.Equipment
LEFT JOIN JCJM 
       ON EMBF.JCCo = JCJM.JCCo
      AND EMBF.Job = JCJM.Job
    WHERE Source = 'EMRev'
      AND EMBF.Co = @Key_EMCo 
      AND EMBF.Mth = @Key_Mth 
      AND EMBF.BatchId = @Key_BatchId 
      AND EMBF.BatchSeq = ISNULL(@Key_Seq_BatchSeq, BatchSeq)
/*    
UNION
   SELECT EMRD.Mth As Key_Mth
        , EMRD.BatchID As Key_BatchId
        , EMRD.Trans As Key_BatchSequence
        , EMRD.Equipment As EquipmentId
        , EMEM.[Description] As EquipmentDescription
        , EMRD.EMGroup As EMGroup
        , EMRD.PhaseGroup As PhaseGroup
        , EMRD.JCPhase As Phase
        , JCJP.[Description] As PhaseDescription
        , EMRD.JCCostType
        , JCCT.[Description] As Abbreviation
        , EMRD.OdoReading As CurrentOdometer
        , EMRD.HourReading As CurrentHourMeter
        , EMRD.TimeUnits As RevTimeUnits
        , EMRD.[Memo] AS Notes
        , EMRD.Job
        , JCJM.[Description] As JobDescription
        , EMRD.JCCo As JCCo
        , EMRD.EMCo As Key_EMCo
        , @VPUserName As VPUserName
        , EMRD.ActualDate As [Date]
     FROM EMRD
LEFT JOIN JCJP 
       ON EMRD.Job = JCJP.Job
      AND EMRD.JCCo = JCJP.JCCo
      AND EMRD.PhaseGroup = JCJP.PhaseGroup 
      AND EMRD.JCPhase = JCJP.Phase
LEFT JOIN JCCT 
       ON EMRD.JCCostType = JCCT.CostType 
      AND EMRD.PhaseGroup = JCCT.PhaseGroup
LEFT JOIN EMEM
       ON EMRD.JCCo = EMEM.EMCo
      AND EMRD.Equipment = EMEM.Equipment
LEFT JOIN JCJM 
       ON EMRD.JCCo = JCJM.JCCo
      AND EMRD.Job = JCJM.Job
    WHERE Source = 'EMRev'
      AND EMRD.EMCo = @Key_EMCo 
      AND EMRD.Mth = @Key_Mth 
      AND EMRD.BatchID = @Key_BatchId 
      AND EMRD.Trans = ISNULL(@Key_Seq_BatchSeq, EMRD.Trans)
*/
    ORDER BY 3
END       
GO
GRANT EXECUTE ON  [dbo].[vpspEMUsageEntryGet] TO [VCSPortal]
GO
