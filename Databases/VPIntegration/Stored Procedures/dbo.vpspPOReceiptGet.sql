SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/18/09
-- Modified By:	GF 11/16/2011 TK-10080
-- Description:	Retrieves the list of PO receipts a user can edit
-- =============================================
CREATE PROCEDURE [dbo].[vpspPOReceiptGet]
	@Key_POCo AS bCompany, @Key_Mth AS bMonth, @Key_BatchId AS bBatchID, @VPUserName AS bVPUserName, @Key_Seq_BatchSeq AS INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
      Co AS Key_POCo
      ,Mth AS Key_Mth
      ,BatchId AS Key_BatchId
      ,BatchSeq AS Key_Seq_BatchSeq
      ,CASE BatchTransType WHEN 'A' THEN 'A - Add' WHEN 'C' THEN 'C - Change' WHEN 'D' THEN 'D - Delete' END AS BatchTransType --Action
      ,POTrans
      ,PO
      ,POItem
      ----TK-10080
      ,POItemLine
      ,RecvdDate
      ,RecvdBy
      ,[Description]
      ,RecvdUnits
      ,RecvdCost
      ,BOUnits
      ,BOCost
      ,Receiver# AS ReceiverNumber
      ,KeyID
      ,@VPUserName AS VPUserName
	FROM dbo.PORB WITH (NOLOCK)
	WHERE Co = @Key_POCo AND Mth = @Key_Mth AND BatchId = @Key_BatchId AND BatchSeq = ISNULL(@Key_Seq_BatchSeq, BatchSeq)
END

GO
GRANT EXECUTE ON  [dbo].[vpspPOReceiptGet] TO [VCSPortal]
GO
