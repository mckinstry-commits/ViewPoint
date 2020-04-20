SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 4/30/2012
-- Modified: Chris G 8/7/12 TK-16896 | B-07454 - Added KeyID
-- Description:	Gets the detail records from PRRQ
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetEquipmentGet]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, @Key_SheetNum SMALLINT,
		-- NOTE: Header text type has to include Phase (bPhase varchar(20)) and Description(varchar(60)) + formatting
		@Phase1HeaderText varchar(100) = NULL OUTPUT,
		@Phase2HeaderText varchar(100) = NULL OUTPUT,
		@Phase3HeaderText varchar(100) = NULL OUTPUT,
		@Phase4HeaderText varchar(100) = NULL OUTPUT,
		@Phase5HeaderText varchar(100) = NULL OUTPUT,
		@Phase6HeaderText varchar(100) = NULL OUTPUT,
		@Phase7HeaderText varchar(100) = NULL OUTPUT,
		@Phase8HeaderText varchar(100) = NULL OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @JCCo bCompany, @Job bJob, @PhaseGroup bGroup

	-- Retreive the dynamic phase header text.  This is used
	-- to replace #PhaseX# in the pPortalDataGridColumns
	SELECT
		 @JCCo = JCCo
		,@Job = Job
		,@PhaseGroup = PhaseGroup
		,@Phase1HeaderText = Phase1
		,@Phase2HeaderText = Phase2
		,@Phase3HeaderText = Phase3
		,@Phase4HeaderText = Phase4
		,@Phase5HeaderText = Phase5
		,@Phase6HeaderText = Phase6
		,@Phase7HeaderText = Phase7
		,@Phase8HeaderText = Phase8
	FROM PRRH
	WHERE
		PRCo = @Key_PRCo
		AND Crew = @Key_Crew
		AND PostDate = @Key_PostDate
		AND SheetNum = @Key_SheetNum
	
	-- Add description to the headers such that description is pulled as a tooltip, which
	-- are formatted as [Header]{description:[Description]} (ex. "1-0102{description:Concrete Phase}")
	SELECT @Phase1HeaderText = @Phase1HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase1HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase2HeaderText = @Phase2HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase2HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase3HeaderText = @Phase3HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase3HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase4HeaderText = @Phase4HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase4HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase5HeaderText = @Phase5HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase5HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase6HeaderText = @Phase6HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase6HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase7HeaderText = @Phase7HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase7HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
	SELECT @Phase8HeaderText = @Phase8HeaderText + '{description:' +  JCJP.[Description] + '}' FROM JCJP WHERE Phase = @Phase8HeaderText AND JCCo = @JCCo AND Job = @Job AND PhaseGroup = @PhaseGroup
		
	SELECT
		 PRRQ.PRCo As Key_PRCo
		,PRRQ.Crew AS Key_Crew
		,PRRQ.PostDate As Key_PostDate
		,PRRQ.SheetNum AS Key_SheetNum
		,PRRQ.EMCo AS Key_EMCo
		,PRRQ.EMGroup AS Key_EMGroup
		,PRRQ.Equipment AS Key_Equipment
		,EMEM.[Description] AS EquipmentDescription
		,CAST(PRRQ.LineSeq AS VARCHAR) AS Key_LineSeq -- use VARCHAR for '+' default
		,PRRQ.Employee
		,(PREH.LastName + ', ' + PREH.FirstName) AS EmployeeName
		,PRRH.PhaseGroup -- For Cost Type lookup
		,PRRH.Phase1 AS PhaseEquipmentEntry1
		,PRRQ.Phase1Usage	
		,PRRQ.Phase1CType
		,PRRQ.Phase1Rev
		,PRRH.Phase2 AS PhaseEquipmentEntry2
		,PRRQ.Phase2Usage	
		,PRRQ.Phase2CType
		,PRRQ.Phase2Rev
		,PRRH.Phase3 AS PhaseEquipmentEntry3
		,PRRQ.Phase3Usage	
		,PRRQ.Phase3CType
		,PRRQ.Phase3Rev
		,PRRH.Phase4 AS PhaseEquipmentEntry4
		,PRRQ.Phase4Usage	
		,PRRQ.Phase4CType
		,PRRQ.Phase4Rev
		,PRRH.Phase5 AS PhaseEquipmentEntry5
		,PRRQ.Phase5Usage	
		,PRRQ.Phase5CType
		,PRRQ.Phase5Rev
		,PRRH.Phase6 AS PhaseEquipmentEntry6
		,PRRQ.Phase6Usage	
		,PRRQ.Phase6CType
		,PRRQ.Phase6Rev
		,PRRH.Phase7 AS PhaseEquipmentEntry7
		,PRRQ.Phase7Usage	
		,PRRQ.Phase7CType
		,PRRQ.Phase7Rev
		,PRRH.Phase8 AS PhaseEquipmentEntry8
		,PRRQ.Phase8Usage	
		,PRRQ.Phase8CType
		,PRRQ.Phase8Rev		
		,ISNULL(PRRQ.TotalUsage, 0) AS TotalUsage
		,PRRQ.KeyID
	FROM PRRQ
	LEFT JOIN PRRH WITH (NOLOCK) ON PRRH.PRCo = @Key_PRCo AND PRRH.Crew = @Key_Crew AND PRRH.PostDate = @Key_PostDate AND PRRH.SheetNum = @Key_SheetNum
	LEFT JOIN EMEM WITH (NOLOCK) ON EMEM.EMCo = PRRQ.EMCo AND EMEM.Equipment = PRRQ.Equipment
	LEFT JOIN PREH WITH (NOLOCK) ON PREH.PRCo = @Key_PRCo AND PREH.Employee = PRRQ.Employee
	WHERE
		PRRQ.PRCo = @Key_PRCo
		AND PRRQ.Crew = @Key_Crew
		AND PRRQ.PostDate = @Key_PostDate
		AND PRRQ.SheetNum = @Key_SheetNum
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetEquipmentGet] TO [VCSPortal]
GO
