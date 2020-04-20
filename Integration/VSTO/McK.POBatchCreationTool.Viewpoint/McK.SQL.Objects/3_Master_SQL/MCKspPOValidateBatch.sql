USE [Viewpoint]
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspPOValidateBatch' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspPOValidateBatch'
	DROP PROCEDURE dbo.MCKspPOValidateBatch
End
GO

Print 'CREATE PROCEDURE dbo.MCKspPOValidateBatch'
GO

CREATE Procedure [dbo].MCKspPOValidateBatch
( 
	@Rbatchid bBatchID  
)
AS
/*
	AUTHOR:	Leo Gurdian
	PURPOSE: Validate all Staged POs: valid Company, MCK PO exists, and PO is OPEN
	HISTORY:	
	-------	  -----------------------
	12.12.2018 LG - removed (POCo = JCCo) condition because there are records with missing JCCo in POHD per Kevin Schrock 12.13.2018
	03.29.2018 LG - Created
*/
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @batchid bBatchID = @Rbatchid
	Declare @errmsg varchar(800)

	BEGIN TRY

		BEGIN

		/* Insert PO Request numbers */
		Update dbo.MCKPOLoad 
		Set PO = x.PO
		From (SELECT p.PO, p.udMCKPONumber FROM dbo.POHD p with (nolock) 
										  INNER JOIN dbo.APVM a WITH(nolock) 
											ON p.VendorGroup = a.VendorGroup 
												AND p.Vendor = a.Vendor 
				) x
		Where x.udMCKPONumber = MCKPO

		/* validate PR Company */
		Insert into dbo.MCKPOerror
		(JCCo, BatchNum, MCKPO, PO, BatchMth, ErrMsg, ErrDate)
		(Select JCCo, BatchNum, MCKPO, PO, BatchMth, 'Invalid Co', GetDate()
		From dbo.MCKPOLoad
		Where NOT EXISTS (Select 1 From dbo.bHQCO Where HQCo = MCKPOLoad.JCCo) 
			  AND BatchNum = @batchid);

		/* validate PO exists */
		Insert into dbo.MCKPOerror
		(JCCo, BatchNum, MCKPO, PO, BatchMth, ErrMsg, ErrDate)
		(Select JCCo, BatchNum, MCKPO, PO, BatchMth, 'MCK PO not found in PO header record', GetDate()
		From dbo.MCKPOLoad a
		Where NOT EXISTS (
							Select 1 FROM POHD with (nolock) Join APVM with(nolock) 
										ON POHD.VendorGroup = APVM.VendorGroup 
											AND POHD.Vendor = APVM.Vendor 
										WHERE POHD.udMCKPONumber = MCKPO 
						 )
				AND NOT EXISTS (Select 1 from dbo.MCKPOerror rr Where BatchNum = @batchid AND rr.MCKPO = a.MCKPO AND rr.PO = a.PO AND BatchNum = @batchid));

		/* validate PO is OPEN */
		Insert into dbo.MCKPOerror
		(JCCo, BatchNum, MCKPO, PO, BatchMth, ErrMsg, ErrDate)
		(Select JCCo, BatchNum, MCKPO, PO, BatchMth, 'MCK PO is not OPEN or Closed', GetDate()
		From dbo.MCKPOLoad a
		Where Not Exists (
								Select 1 FROM POHD with (nolock) Join APVM with(nolock) 
											ON POHD.VendorGroup = APVM.VendorGroup 
											and POHD.Vendor = APVM.Vendor 
											WHERE POHD.udMCKPONumber = MCKPO 
												  AND POHD.Status = 0 or POHD.Status = 2 -- OPEN
								)
				AND Not Exists (Select 1 from dbo.MCKPOerror rr Where BatchNum = @batchid AND rr.MCKPO = a.MCKPO AND rr.PO = a.PO
				AND BatchNum = @batchid));

		/* mark failed records */
		Update MCKPOLoad
		Set Status = 'F'
		From (Select JCCo, BatchNum, MCKPO, PO, BatchMth From dbo.MCKPOerror Where BatchNum = @batchid) x 
							JOIN dbo.MCKPOLoad p ON
								p.JCCo = x.JCCo
							AND p.BatchNum = x.BatchNum
							AND p.MCKPO = x.MCKPO
							AND p.BatchMth = x.BatchMth;

	   END

	END TRY

	BEGIN CATCH
		Set @errmsg =  ERROR_PROCEDURE() + ', ' + 'Line:' + CAST(ERROR_LINE() as VARCHAR(MAX)) + ' | ' + ERROR_MESSAGE();
		Goto i_exit
	END CATCH

i_exit:
	if (@errmsg <> '')
		Begin
		 RAISERROR(@errmsg, 11, -1);
		END
        
	Select -1; -- success
End

GO

Grant EXECUTE ON dbo.MCKspPOValidateBatch TO [MCKINSTRY\Viewpoint Users]


--and Status = 0 -- OPEN
--and udMCKPONumber = '10035064'

--exec MCKspPOValidateBatch 7693