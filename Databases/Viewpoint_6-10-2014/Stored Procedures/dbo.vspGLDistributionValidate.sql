SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/15/13
-- Description:	Generic GL Distribution validation routine
-- Modified:	JVH 6/24/13 - TFS-53342	Modified to support SM Flat Price Billing
-- =============================================
CREATE PROCEDURE [dbo].[vspGLDistributionValidate]
	@Source bSource, @BatchCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT dbo.bHQCC (Co, Mth, BatchId, GLCo)
	SELECT DISTINCT vGLDistribution.Co, vGLDistribution.Mth, vGLDistribution.BatchId, vGLDistribution.GLCo
	FROM dbo.vGLDistribution
		LEFT JOIN dbo.bHQCC ON vGLDistribution.Co = bHQCC.Co AND vGLDistribution.Mth = bHQCC.Mth AND vGLDistribution.BatchId = bHQCC.BatchId AND vGLDistribution.GLCo = bHQCC.GLCo
	WHERE vGLDistribution.[Source] = @Source AND vGLDistribution.Co = @BatchCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId AND vGLDistribution.GLCo IS NOT NULL AND bHQCC.GLCo IS NULL

	DECLARE @HQBESeq int

	SET @HQBESeq = ISNULL((SELECT MAX(Seq) FROM dbo.bHQBE WHERE Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId), 0)

	INSERT dbo.bHQBE (Co, Mth, BatchId, Seq, ErrorText)
	SELECT @BatchCo, @BatchMonth, @BatchId, @HQBESeq + ROW_NUMBER() OVER (ORDER BY BatchSeq, Line),
		--Use cast instead of ToString so that if the value is BatchSeq or Line is null then the preceding text won't be added.
		 dbo.vfToString('Seq# ' + CAST(BatchSeq AS varchar(MAX))) + dbo.vfToString(', Line# ' + CAST(Line AS varchar(MAX))) + ' - ' + ErrorText
	FROM
	(
		--Basic GL validation
		SELECT DISTINCT vGLDistribution.BatchSeq, vGLDistribution.Line,
			CASE
				WHEN vGLDistributionInterface.GLDistributionInterfaceID IS NULL THEN 'Interface setup not supplied'
				WHEN vGLDistribution.GLCo IS NULL THEN 'GL Company not supplied'
				WHEN vGLDistribution.GLAccount IS NULL THEN 'GL Account not supplied'
				WHEN vGLDistribution.Amount IS NULL THEN 'Amount not supplied'
				WHEN vGLDistribution.ActDate IS NULL THEN 'Actual Date not supplied'
				WHEN vGLDistributionInterface.InterfaceLevel <> 0 AND vGLDistributionInterface.Journal IS NULL THEN 'Journal not supplied'
				WHEN vGLDistributionInterface.InterfaceLevel = 1 AND vGLDistributionInterface.SummaryDescription IS NULL THEN 'Summary Description not supplied'
				WHEN vGLDistributionInterface.InterfaceLevel > 1 AND vGLDistribution.[Description] IS NULL THEN 'Detail Description not supplied'
				WHEN bGLCO.GLCo IS NULL THEN 'Invalid GL Company!'
				WHEN vfGLClosedMonths.IsMonthOpen = 0 THEN 'Month must be between ' + dbo.vfToMonthString(vfGLClosedMonths.BeginMonth) + ' and ' + dbo.vfToMonthString(vfGLClosedMonths.EndMonth)
				WHEN GLFiscalYear.FYEMO IS NULL THEN 'Must first add a Fiscal Year in General Ledger.'
				WHEN bGLAC.GLAcct IS NULL THEN AccountMessage + ' not found!'
				WHEN bGLAC.AcctType = 'H' THEN AccountMessage + ' is a Heading Account!'
				WHEN bGLAC.Active = 'N' THEN AccountMessage + ' is inactive!'
				WHEN vGLDistribution.GLAccountSubType = 'N' AND bGLAC.SubType IS NOT NULL THEN AccountMessage + ' is Subledger Type: ' + dbo.vfToString(bGLAC.SubType) + '.  Must be null!'
				WHEN vGLDistribution.GLAccountSubType <> bGLAC.SubType THEN AccountMessage + ' is Subledger Type: ' + dbo.vfToString(bGLAC.SubType) + '.  Must be ' + dbo.vfToString(vGLDistribution.GLAccountSubType) + ' or null!'
				WHEN bGLJR.Jrnl IS NULL THEN 'GL Journal ' + dbo.vfToString(vGLDistributionInterface.Journal) + ' not on file for GL Company # ' + dbo.vfToString(vGLDistribution.GLCo) + ' .'
			END ErrorText
		FROM dbo.vGLDistribution
			LEFT JOIN dbo.bGLCO ON vGLDistribution.GLCo = bGLCO.GLCo
			LEFT JOIN dbo.vfGLClosedMonths(@Source, @BatchMonth) ON vGLDistribution.GLCo = vfGLClosedMonths.GLCo
			OUTER APPLY
			(
				SELECT TOP 1 FYEMO
				FROM dbo.bGLFY
				WHERE vGLDistribution.GLCo = GLCo AND BeginMth <= @BatchMonth AND FYEMO >= @BatchMonth
			) GLFiscalYear
			LEFT JOIN dbo.bGLAC ON vGLDistribution.GLCo = bGLAC.GLCo AND vGLDistribution.GLAccount = bGLAC.GLAcct
			LEFT JOIN dbo.vGLDistributionInterface ON vGLDistribution.[Source] = vGLDistributionInterface.[Source] AND vGLDistribution.Co = vGLDistributionInterface.Co AND vGLDistribution.Mth = vGLDistributionInterface.Mth AND vGLDistribution.BatchId = vGLDistributionInterface.BatchId
			LEFT JOIN dbo.bGLJR ON vGLDistribution.GLCo = bGLJR.GLCo AND vGLDistributionInterface.Journal = bGLJR.Jrnl
			CROSS APPLY (SELECT 'GL Co: ' + dbo.vfToString(vGLDistribution.GLCo) + ' GL Account: ' + dbo.vfToString(vGLDistribution.GLAccount) AccountMessage) GetAccountMessage
		WHERE vGLDistribution.Source = @Source AND vGLDistribution.Co = @BatchCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId
		
		UNION ALL
		
		--Validate GL distributions balance
		SELECT vGLDistribution.BatchSeq, vGLDistribution.Line, 'GL distributions don''t balance!'
		FROM dbo.vGLDistribution
		WHERE vGLDistribution.Source = @Source AND vGLDistribution.Co = @BatchCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId
		GROUP BY vGLDistribution.GLCo, vGLDistribution.BatchSeq, vGLDistribution.Line
		HAVING SUM(vGLDistribution.Amount) <> 0
	) GetErrorText
	WHERE ErrorText IS NOT NULL

	IF @@ROWCOUNT <> 0 RETURN 1

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspGLDistributionValidate] TO [public]
GO
