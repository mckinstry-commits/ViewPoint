SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 2/24/10
-- Description:	Retrieves JC Progress Entry Phases belonging to the given batch
-- =============================================
CREATE PROCEDURE [dbo].[vpspJCProgressGet]
	@Key_JCCo AS bCompany, @Key_BatchId AS bBatchID, @Key_Mth AS bMonth, 
	@VPUserName AS bVPUserName, @Key_BatchSeq AS int = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Get the Phase and Cost Type filters saved from V6
	DECLARE @Options varchar(8000)
	DECLARE @PhaseOption varchar(1)
	DECLARE @CostTypeOption varchar(1)
	DECLARE @CostTypeList varchar(8000)

	-- Get users form options
	SELECT @Options = Options FROM DDFU WHERE VPUserName=@VPUserName AND Form = 'JCProgress'

	DECLARE @SubOption varchar(8000)
	DECLARE @SubOptionValue varchar(8000)
	DECLARE @retstring varchar(8000)
	DECLARE @delimpos int

	-- Parse the format options formated as "Phase;[A|S|N]:CostType;[A|S|P|I]:CTList[1,2,3,...]"
	WHILE len(@Options) > 0 AND (@delimpos IS NULL OR @delimpos > 0)
		BEGIN
			EXEC bspParseString @Options, ':', @delimpos output, @retstring output, @Options output, null
			EXEC bspParseString @retstring, ';', null, @SubOption output, @SubOptionValue output, null
			
			IF @SubOption = 'Phase' SET @PhaseOption = @SubOptionValue
			IF @SubOption = 'CostType' SET @CostTypeOption = @SubOptionValue
			IF @SubOption = 'CTList' SET @CostTypeList = @SubOptionValue
		END

	DECLARE @CostTypes AS TABLE
	(
		CostTypeID int
	)

	-- Convert the cost type list to a temp table
	SET @delimpos = null
	WHILE len(@CostTypeList) > 0 AND (@delimpos IS NULL OR @delimpos > 0)
		BEGIN
			EXEC bspParseString @CostTypeList, ',', @delimpos output, @retstring output, @CostTypeList output, null
			INSERT INTO @CostTypes VALUES (CAST(@retstring AS int))
		END

	-- END Get the Phase and Cost Type filters saved from V6

	DECLARE @BatchStatus AS tinyint
	
	SELECT @BatchStatus = [Status] 
	FROM HQBC
	WHERE 
		Source = 'JC Progres' 
		AND HQBC.Co = @Key_JCCo 
		AND HQBC.Mth = @Key_Mth
		AND HQBC.BatchId = @Key_BatchId
		AND CreatedBy = @VPUserName 
		AND (InUseBy = @VPUserName OR InUseBy IS NULL) 		
	
	IF (@BatchStatus = 0) -- OPEN
		BEGIN
			SELECT 
				JCPP.Co AS Key_JCCo
				,JCPP.BatchSeq AS Key_BatchSeq
				,dtl.Mth AS Key_Mth
				,dtl.BatchId AS Key_BatchId
				,JCPP.KeyID AS KeyID
				,@VPUserName AS VPUserName
				,JCJP.Phase AS Phase
				,JCJP.Description AS PhaseDescription
				,JCCT.Abbreviation AS CostType
				,JCJP.Item AS ContractItem
				,JCCI.Description AS ContractItemDescription	
				,JCPP.UM AS UoM
				,JCPP.ActualUnits AS PeriodComplete
				,(JCPP.ActualUnits + dtl.CurrentCompleted) AS CompleteToDate	
				,CAST((JCPP.ProgressCmplt * 100.0) AS numeric(6,2)) AS TotalPercentage			
			FROM JCPP
			left join JCCO with (nolock) on JCCO.JCCo = JCPP.Co
			left join JCJM JCJM with (nolock) on JCJM.JCCo = JCPP.Co and JCJM.Job = JCPP.Job 
			left join JCCM JCCM with (nolock) on JCCM.JCCo = JCJM.JCCo and JCCM.Contract = JCJM.Contract
			left join HQCO HQCOPRCo with (nolock) on HQCOPRCo.HQCo = JCPP.PRCo
			left join PRCR PRCR with (nolock) on PRCR.PRCo = JCPP.PRCo and PRCR.Crew = JCPP.Crew
			left join JCCT JCCT with (nolock) on JCCT.PhaseGroup = JCPP.PhaseGroup and JCCT.CostType = JCPP.CostType
			left join JCCH JCCH with (nolock) on JCCH.JCCo = JCPP.Co and JCCH.Job = JCPP.Job and JCCH.PhaseGroup = JCPP.PhaseGroup and JCCH.Phase = JCPP.Phase and JCCH.CostType = JCPP.CostType
			left join JCJP JCJP with (nolock) on JCJP.JCCo = JCPP.Co and JCJP.Job = JCPP.Job and JCJP.PhaseGroup = JCPP.PhaseGroup and JCJP.Phase = JCPP.Phase
			left join JCCI JCCI with (nolock) on JCCI.JCCo = JCJP.JCCo and JCCI.Contract = JCJP.Contract and JCCI.Item = JCJP.Item
			left join JCPC JCPC with (nolock) on JCPC.PhaseGroup = JCPP.PhaseGroup and JCPC.Phase = JCPP.Phase and JCPC.CostType = JCPP.CostType
			left join JCPPCostTypesDtl s with (nolock) on s.PhaseGroup=JCPP.PhaseGroup and s.CostType=JCPP.CostType and s.Co = JCPP.Co and s.Mth = JCPP.Mth and s.BatchId = JCPP.BatchId
			left join JCPPJCCD dtl with (nolock) on dtl.Co=JCPP.Co and dtl.Mth=JCPP.Mth and dtl.BatchId=JCPP.BatchId
			and dtl.BatchSeq=JCPP.BatchSeq and dtl.Job=JCPP.Job and dtl.PhaseGroup=JCPP.PhaseGroup
			and dtl.Phase=JCPP.Phase and dtl.CostType=JCPP.CostType
			WHERE
				JCPP.Co = @Key_JCCo AND		
				dtl.BatchId = @Key_BatchId AND
				dtl.Mth = @Key_Mth AND
				JCPP.BatchSeq = ISNULL(@Key_BatchSeq, JCPP.BatchSeq)
				-- Integreage Phase and Cost type options in the WHERE clause
				and (    (@PhaseOption = 'S' AND exists (select top 1 1 from JCPPPhases p with (nolock) where  p.Co = JCPP.Co and p.Month=JCPP.Mth and p.BatchId= JCPP.BatchId and p.Job = JCPP.Job and p.Phase=JCPP.Phase))
					  OR (@PhaseOption = 'N' AND JCPP.Phase = '')
					  OR (@PhaseOption = 'A')
					  OR (@PhaseOption is null)
					)
				and (    (@CostTypeOption = 'A' AND JCJP.ActiveYN='Y')
					  OR (@CostTypeOption = 'S'	AND JCCH.CostType in (select CostTypeID from @CostTypes))
					  OR (@CostTypeOption = 'P' AND JCCH.PhaseUnitFlag='Y' and JCJP.ActiveYN='Y')
					  OR (@CostTypeOption = 'I' AND JCCH.ItemUnitFlag='Y' and JCJP.ActiveYN='Y')
					)
			ORDER BY
				JCPP.BatchSeq
		END
	IF (@BatchStatus = 5) -- POSTED (should not get any other status then 0 or 5)
		BEGIN
			-- For posted batch, need to join to JCCD table.  JCPP gets cleared once posted.
			SELECT 
				JCCD.JCCo AS Key_JCCo
				,JCCD.KeyID AS Key_BatchSeq -- There is no batch seq in detail table, so conjure one up so the table Key_ constraint in Connects is statisfied
				,JCCD.Mth AS Key_Mth
				,JCCD.BatchId AS Key_BatchId
				,JCCD.KeyID AS KeyID
				,JCJP.Phase AS Phase
				,JCJP.Description AS PhaseDescription
				,JCCT.Abbreviation AS CostType
				,JCJP.Item AS ContractItem
				,JCCI.Description AS ContractItemDescription	
				,JCCD.UM AS UoM
				,0 AS PeriodComplete
				,JCCD.ActualUnits AS CompleteToDate	
				,CAST((JCCD.ProgressCmplt * 100.0) AS numeric(6,2)) AS TotalPercentage			
			FROM JCCD
			left join JCCO with (nolock) on JCCO.JCCo = JCCD.JCCo
			left join JCJM JCJM with (nolock) on JCJM.JCCo = JCCD.JCCo and JCJM.Job = JCCD.Job 
			left join JCCM JCCM with (nolock) on JCCM.JCCo = JCJM.JCCo and JCCM.Contract = JCJM.Contract
			left join HQCO HQCOPRCo with (nolock) on HQCOPRCo.HQCo = JCCD.PRCo
			left join PRCR PRCR with (nolock) on PRCR.PRCo = JCCD.PRCo and PRCR.Crew = JCCD.Crew
			left join JCCT JCCT with (nolock) on JCCT.PhaseGroup = JCCD.PhaseGroup and JCCT.CostType = JCCD.CostType
			left join JCCH JCCH with (nolock) on JCCH.JCCo = JCCD.JCCo and JCCH.Job = JCCD.Job and JCCH.PhaseGroup = JCCD.PhaseGroup and JCCH.Phase = JCCD.Phase and JCCH.CostType = JCCD.CostType
			left join JCJP JCJP with (nolock) on JCJP.JCCo = JCCD.JCCo and JCJP.Job = JCCD.Job and JCJP.PhaseGroup = JCCD.PhaseGroup and JCJP.Phase = JCCD.Phase
			left join JCCI JCCI with (nolock) on JCCI.JCCo = JCJP.JCCo and JCCI.Contract = JCJP.Contract and JCCI.Item = JCJP.Item
			left join JCPC JCPC with (nolock) on JCPC.PhaseGroup = JCCD.PhaseGroup and JCPC.Phase = JCCD.Phase and JCPC.CostType = JCCD.CostType
			left join JCPPCostTypesDtl s with (nolock) on s.PhaseGroup=JCCD.PhaseGroup and s.CostType=JCCD.CostType and s.Co = JCCD.JCCo and s.Mth = JCCD.Mth and s.BatchId = JCCD.BatchId
			WHERE
				JCCD.JCCo = @Key_JCCo AND		
				JCCD.BatchId = @Key_BatchId AND
				JCCD.Mth = @Key_Mth
		END
	ELSE
		RAISERROR('Batch selected must be in the Open or Posted status.', 16, 1)
	
END
GO
GRANT EXECUTE ON  [dbo].[vpspJCProgressGet] TO [VCSPortal]
GO
