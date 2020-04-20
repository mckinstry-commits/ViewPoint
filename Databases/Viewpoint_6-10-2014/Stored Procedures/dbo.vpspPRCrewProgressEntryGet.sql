SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Joe AmRhein
-- Create date: 4/18/12
-- Modified Date: 5/25/12 ChrisG - TK-15227 | B-09776 - Added phase descriptions
-- Description:	Gets the Crew Progress Entry List from PRRH
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewProgressEntryGet]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate = NULL, @Key_SheetNum SMALLINT = NULL, @thePhaseNum SMALLINT = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 IF @thePhaseNum IS NULL
 BEGIN 
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase1 AS Phase
		,Phase1CostType AS CostType
		,dbo.vfPRTSUMforPhase(p1.PRCo, p1.JCCo, p1.Job, p1.Phase1, p1.PhaseGroup, p1.Phase1CostType) AS UM
		,Phase1Units AS Units
		,1 AS Key_PhaseNum
		,p1.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p1.KeyID
	 FROM PRRH p1 
	 INNER JOIN JCJP ON JCJP.JCCo = p1.JCCo 
		AND JCJP.Job = p1.Job AND JCJP.PhaseGroup = p1.PhaseGroup AND JCJP.Phase = p1.Phase1
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase1 IS NOT NULL
	 UNION ALL
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase2 AS Phase
		,Phase2CostType AS CostType
		,dbo.vfPRTSUMforPhase(p2.PRCo, p2.JCCo, p2.Job, p2.Phase2, p2.PhaseGroup, p2.Phase2CostType) AS UM
		,Phase2Units AS Units
		,2 AS Key_PhaseNum
		,p2.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p2.KeyID
	 FROM PRRH p2 
	 INNER JOIN JCJP ON JCJP.JCCo = p2.JCCo 
		AND JCJP.Job = p2.Job AND JCJP.PhaseGroup = p2.PhaseGroup AND JCJP.Phase = p2.Phase2
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase2 IS NOT NULL
	 UNION ALL
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase3 AS Phase
		,Phase3CostType AS CostType
		,dbo.vfPRTSUMforPhase(p3.PRCo, p3.JCCo, p3.Job, p3.Phase3, p3.PhaseGroup, p3.Phase3CostType) AS UM
		,Phase3Units AS Units
		,3 AS Key_PhaseNum
		,p3.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p3.KeyID
	 FROM PRRH p3 
	 INNER JOIN JCJP ON JCJP.JCCo = p3.JCCo 
		AND JCJP.Job = p3.Job AND JCJP.PhaseGroup = p3.PhaseGroup AND JCJP.Phase = p3.Phase3
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase3 IS NOT NULL
	 UNION ALL
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase4 AS Phase
		,Phase4CostType AS CostType
		,dbo.vfPRTSUMforPhase(p4.PRCo, p4.JCCo, p4.Job, p4.Phase4, p4.PhaseGroup, p4.Phase4CostType) AS UM
		,Phase4Units AS Units
		,4 AS Key_PhaseNum
		,p4.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p4.KeyID
	 FROM PRRH p4 
	 INNER JOIN JCJP ON JCJP.JCCo = p4.JCCo 
		AND JCJP.Job = p4.Job AND JCJP.PhaseGroup = p4.PhaseGroup AND JCJP.Phase = p4.Phase4
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase4 IS NOT NULL
	 UNION ALL
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase5 AS Phase
		,Phase5CostType AS CostType
		,dbo.vfPRTSUMforPhase(p5.PRCo, p5.JCCo, p5.Job, p5.Phase5, p5.PhaseGroup, p5.Phase5CostType) AS UM
		,Phase5Units AS Units
		,5 AS Key_PhaseNum
		,p5.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p5.KeyID
	 FROM PRRH p5 
	 INNER JOIN JCJP ON JCJP.JCCo = p5.JCCo 
		AND JCJP.Job = p5.Job AND JCJP.PhaseGroup = p5.PhaseGroup AND JCJP.Phase = p5.Phase5
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase5 IS NOT NULL
	 UNION ALL
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase6 AS Phase
		,Phase6CostType AS CostType
		,dbo.vfPRTSUMforPhase(p6.PRCo, p6.JCCo, p6.Job, p6.Phase6, p6.PhaseGroup, p6.Phase6CostType) AS UM
		,Phase6Units AS Units
		,6 AS Key_PhaseNum
		,p6.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p6.KeyID
	 FROM PRRH p6 
	 INNER JOIN JCJP ON JCJP.JCCo = p6.JCCo 
		AND JCJP.Job = p6.Job AND JCJP.PhaseGroup = p6.PhaseGroup AND JCJP.Phase = p6.Phase6
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase6 IS NOT NULL
	 UNION ALL
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase7 AS Phase
		,Phase7CostType AS CostType
		,dbo.vfPRTSUMforPhase(p7.PRCo, p7.JCCo, p7.Job, p7.Phase7, p7.PhaseGroup, p7.Phase7CostType) AS UM
		,Phase7Units AS Units
		,7 AS Key_PhaseNum
		,p7.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p7.KeyID
	 FROM PRRH p7 
	 INNER JOIN JCJP ON JCJP.JCCo = p7.JCCo 
		AND JCJP.Job = p7.Job AND JCJP.PhaseGroup = p7.PhaseGroup AND JCJP.Phase = p7.Phase7
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase7 IS NOT NULL
	 UNION ALL
	 SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
		,Phase8 AS Phase
		,Phase8CostType AS CostType
		,dbo.vfPRTSUMforPhase(p8.PRCo, p8.JCCo, p8.Job, p8.Phase8, p8.PhaseGroup, p8.Phase8CostType) AS UM
		,Phase8Units AS Units
		,8 AS Key_PhaseNum
		,p8.PhaseGroup
		,JCJP.[Description] AS PhaseDescription
		,p8.KeyID
	 FROM PRRH p8 
	 INNER JOIN JCJP ON JCJP.JCCo = p8.JCCo 
		AND JCJP.Job = p8.Job AND JCJP.PhaseGroup = p8.PhaseGroup AND JCJP.Phase = p8.Phase8
	 WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase8 IS NOT NULL
	 
 END
 ELSE
 BEGIN
 IF @thePhaseNum = 1
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase1 AS Phase
			,Phase1CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase1, PhaseGroup, Phase1CostType) AS UM
			,Phase1Units AS Units
			,1 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase1 IS NOT NULL
		END
		
		IF @thePhaseNum = 2
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase2 AS Phase
			,Phase2CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase2, PhaseGroup, Phase2CostType) AS UM
			,Phase2Units AS Units
			,2 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase2 IS NOT NULL
		END
		
		IF @thePhaseNum = 3
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase3 AS Phase
			,Phase3CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase3, PhaseGroup, Phase3CostType) AS UM
			,Phase3Units AS Units
			,3 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase3 IS NOT NULL
		END
		
		IF @thePhaseNum = 4
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase4 AS Phase
			,Phase4CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase4, PhaseGroup, Phase4CostType) AS UM
			,Phase4Units AS Units
			,4 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase4 IS NOT NULL
		END
		
		IF @thePhaseNum = 5
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase5 AS Phase
			,Phase5CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase5, PhaseGroup, Phase5CostType) AS UM
			,Phase5Units AS Units
			,5 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase5 IS NOT NULL
		END
		
		IF @thePhaseNum = 6
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase6 AS Phase
			,Phase6CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase6, PhaseGroup, Phase6CostType) AS UM
			,Phase6Units AS Units
			,6 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase6 IS NOT NULL
		END
		
		IF @thePhaseNum = 7
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase7 AS Phase
			,Phase7CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase7, PhaseGroup, Phase7CostType) AS UM
			,Phase7Units AS Units
			,7 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase7 IS NOT NULL
		END
		
		IF @thePhaseNum = 8
		BEGIN
			SELECT PRCo AS Key_PRCo, Crew AS Key_Crew, PostDate AS Key_PostDate, SheetNum AS Key_SheetNum
			,Phase8 AS Phase
			,Phase8CostType AS CostType
			,dbo.vfPRTSUMforPhase(PRCo, JCCo, Job, Phase8, PhaseGroup, Phase8CostType) AS UM
			,Phase8Units AS Units
			,8 AS Key_PhaseNum
			,PhaseGroup
			,KeyID
			FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND SheetNum = @Key_SheetNum AND PostDate = @Key_PostDate AND Phase8 IS NOT NULL
		END
 END
 
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewProgressEntryGet] TO [VCSPortal]
GO
