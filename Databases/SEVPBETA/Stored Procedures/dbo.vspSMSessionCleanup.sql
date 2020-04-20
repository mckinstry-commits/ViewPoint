SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/11/11
-- Description:	Delete a specific session or all sessions for a company if there
--              are no invoices in the session.
-- =============================================
CREATE PROCEDURE dbo.vspSMSessionCleanup
		@SMCo tinyint, 
		@SMSessionID int=NULL,
		@msg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DELETE SMSession
		FROM SMSession
		LEFT JOIN SMInvoiceSession 
			ON SMSession.SMCo=SMInvoiceSession.SMCo 
			AND SMSession.SMSessionID=SMInvoiceSession.SMSessionID 
		WHERE SMSession.SMCo=@SMCo
			AND SMInvoiceSession.SMSessionID IS NULL
			AND (@SMSessionID IS NULL OR SMSession.SMSessionID=@SMSessionID)
		
		RETURN 0
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionCleanup] TO [public]
GO
