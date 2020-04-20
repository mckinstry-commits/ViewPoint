USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mspLogDetailInvoiceAction' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.mspLogDetailInvoiceAction'
	DROP PROCEDURE dbo.mspLogDetailInvoiceAction
End
GO

Print 'CREATE PROCEDURE dbo.mspLogDetailInvoiceAction'
GO


Create PROCEDURE dbo.mspLogDetailInvoiceAction
(
	@User				bVPUserName 
,  @ActionInt		SMALLINT
,	@Version			VARCHAR(7)
,	@JCCo				bCompany
,  @InvoiceFrom	VARCHAR(10)
,  @InvoiceTo		VARCHAR(10)
,	@DateFrom		bMonth = null
,	@DateTo			bMonth = null
,	@Details			VARCHAR(50)
,	@ErrorTxt		VARCHAR(255)
)
AS
/* ========================================================================
	Object Name: dbo.mspLogDetailInvoiceAction
	Author:		 Gurdian, Leo
	Create date: 10/30/17
	Modified:	 
	Description: Procedure to populate the Detail Invoice log table.
	Update Hist: 
	L.Gurdian   10/30/17  initial proc creation
	========================================================================
*/
DECLARE @Action AS VARCHAR(20)
	, @ActionDate AS DateTime 

SET @Action = CASE @ActionInt
				WHEN 0 THEN 'REPORT'
            WHEN 1 THEN 'COPY OFFLINE'
				WHEN 2 THEN 'EMAIL'
				WHEN 3 THEN 'INVALID USER'
				WHEN 4 THEN 'ERROR'
				ELSE 'UNKNOWN' 
		END

SET @ActionDate = SYSDATETIME();

BEGIN
	INSERT INTO dbo.mckDetailInvoiceLog (VPUserName, DateTime, Version, JCCo, InvoiceFrom, InvoiceTo, DateFrom, DateTo, Action, Details, ErrorText)
		VALUES (@User, @ActionDate, @Version, @JCCo, @InvoiceFrom, @InvoiceTo, @DateFrom, @DateTo, @Action, @Details, @ErrorTxt)
END

GO

Grant EXECUTE ON dbo.mspLogDetailInvoiceAction TO [MCKINSTRY\Viewpoint Users]