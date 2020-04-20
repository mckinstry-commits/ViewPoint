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
	3.29.18	- Created
*/

SET NOCOUNT ON;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @batchid bBatchID = @Rbatchid
Declare @errmsg varchar(800)


Begin

	Begin try

		Begin

		/* Insert PO Request numbers */
		Update MCKPOLoad 
		Set PO = x.PO
		From (Select PO, udMCKPONumber FROM POHD with (nolock) Join APVM with(nolock) 
							 ON POHD.VendorGroup = APVM.VendorGroup 
								  and POHD.Vendor = APVM.Vendor 
							 WHERE POCo = JCCo 
									 and POHD.VendorGroup	= isnull(NULL,POHD.VendorGroup) 
									 and POHD.Vendor			= isnull(NULL, POHD.Vendor)
				) x
		Where x.udMCKPONumber = MCKPO

		/* validate PR Company */
		Insert into dbo.MCKPOerror
		(JCCo, BatchNum, MCKPO, PO, BatchMth, ErrMsg, ErrDate)
		(Select JCCo, BatchNum, MCKPO, PO, BatchMth, 'Invalid Co', GetDate()
		From dbo.MCKPOLoad
		Where Not Exists (Select 1 From dbo.bHQCO Where HQCo = JCCo) 
			   AND BatchNum = @batchid);

		/* validate PO exists */
		Insert into dbo.MCKPOerror
		(JCCo, BatchNum, MCKPO, PO, BatchMth, ErrMsg, ErrDate)
		(Select JCCo, BatchNum, MCKPO, PO, BatchMth, 'Invalid MCK PO', GetDate()
		From dbo.MCKPOLoad a
		Where Not Exists (
								Select 1 FROM POHD with (nolock) Join APVM with(nolock) 
											ON POHD.VendorGroup = APVM.VendorGroup 
											and POHD.Vendor = APVM.Vendor 
											WHERE POCo = JCCo 
													and POHD.VendorGroup = isnull(NULL,POHD.VendorGroup) 
													and POHD.Vendor = isnull(NULL, POHD.Vendor) 
													and POHD.udMCKPONumber = MCKPO 
								)
				AND Not Exists (Select 1 from dbo.MCKPOerror rr Where BatchNum = @batchid AND rr.MCKPO = a.MCKPO AND rr.PO = a.PO
				AND BatchNum = @batchid));


		/* validate PO is OPEN */
		Insert into dbo.MCKPOerror
		(JCCo, BatchNum, MCKPO, PO, BatchMth, ErrMsg, ErrDate)
		(Select JCCo, BatchNum, MCKPO, PO, BatchMth, 'MCK PO is not OPEN or Closed', GetDate()
		From dbo.MCKPOLoad a
		Where Not Exists (
								Select 1 FROM POHD with (nolock) Join APVM with(nolock) 
											ON POHD.VendorGroup = APVM.VendorGroup 
											and POHD.Vendor = APVM.Vendor 
											WHERE POCo = JCCo 
													and POHD.VendorGroup = isnull(NULL,POHD.VendorGroup) 
													and POHD.Vendor = isnull(NULL, POHD.Vendor) 
													and POHD.udMCKPONumber = MCKPO 
													and POHD.Status = 0 or POHD.Status = 2 -- OPEN
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
							AND p.PO = x.PO
							AND p.BatchMth = x.BatchMth;

	   End

	End try

	Begin Catch
		--Print 'Validation failed!'; -- but don't halt, continue processing
		Set @errmsg =  ERROR_PROCEDURE() + ', ' + 'Line:' + cast(ERROR_LINE() as varchar) + ' | ' + ERROR_MESSAGE();
		Goto i_exit
	End Catch

i_exit:
	SET NOCOUNT OFF;

	if (@errmsg != '')
		Begin
		 --RAISERROR(@errmsg, 11, -1);
		 --Print 'failed'
		 Select 0; -- failure
		End

   --Print 'success'
	Select -1; -- success
End

GO

Grant EXECUTE ON dbo.MCKspPOValidateBatch TO [MCKINSTRY\Viewpoint Users]



--and Status = 0 -- OPEN
--and udMCKPONumber = '10035064'

--exec MCKspPOValidateBatch 7693