SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 12/15/2010
-- Description:	Return the lower batch month in an invoice session greater than a supplied batch month.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMInvoiceSessionBatchMonth]
	-- Add the parameters for the stored procedure here
	@SMSessionID int,
	@LastBatchMonth bMonth = null,
	@NextBatchMonth bMonth OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @NextBatchMonth = MIN(BatchMonth)
	FROM SMInvoiceSession
	WHERE SMInvoiceSession.SMSessionID = @SMSessionID
	AND Invoiced = 0
	AND (@LastBatchMonth IS NULL OR BatchMonth > @LastBatchMonth)
END

GO
GRANT EXECUTE ON  [dbo].[vspSMInvoiceSessionBatchMonth] TO [public]
GO
