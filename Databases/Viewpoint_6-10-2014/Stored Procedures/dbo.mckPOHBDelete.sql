SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/28/2014
-- Description:	Procedure to fix/delete broken PO Batch
-- =============================================
CREATE PROCEDURE [dbo].[mckPOHBDelete] 
	-- Add the parameters for the stored procedure here
	@Company bCompany = 0, 
	@BatchMth bMonth = 0
	, @BatchID bBatchID
	, @BatchSeq INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	DELETE FROM dbo.POIB
	WHERE BatchId = @BatchID AND Mth = @BatchMth AND Co = @Company AND BatchSeq = @BatchSeq

	DELETE FROM dbo.POHB
	WHERE BatchId = @BatchID AND Mth = @BatchMth AND Co = @Company AND BatchSeq = @BatchSeq
	
	UPDATE dbo.HQBC
	SET Status = 6
	WHERE BatchId = @BatchID AND Mth = @BatchMth AND Co = @Company

	DELETE FROM dbo.HQBC
	WHERE BatchId = @BatchID AND Mth = @BatchMth AND Co = @Company

	

END
GO
