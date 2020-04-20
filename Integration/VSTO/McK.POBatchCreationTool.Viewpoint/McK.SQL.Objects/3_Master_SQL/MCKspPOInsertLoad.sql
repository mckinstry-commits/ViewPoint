USE [Viewpoint]
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspPOInsertLoad' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspPOInsertLoad'
	DROP PROCEDURE dbo.MCKspPOInsertLoad
End
GO

Print 'CREATE PROCEDURE dbo.MCKspPOInsertLoad'
GO


Create Procedure [dbo].MCKspPOInsertLoad
( @JCCo bCompany,
  @MCKPO Varchar(30),
  @BatchMth bMonth,
  @Rbatchid bBatchID
)
AS
/*
	AUTHOR:	Leo Gurdian
	PURPOSE: Insert POs into staging table
	HISTORY:	
	-------	  -----------------------
	3.29.18	- Created
	4.4.18	- Add PO Request # field - LG
*/

DECLARE @jcco bCompany		= @JCCo
DECLARE @batchmth bMonth	= @BatchMth
DECLARE @batchid bBatchID	= @Rbatchid
DECLARE @mckPO Varchar(30) = @MCKPO

SET NOCOUNT ON;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Begin

		Insert into MCKPOLoad
		(	 JCCo
			,MCKPO
			,PO		-- will get populated in dbo.MCKspPOValidateBatch 
			,BatchNum
			,BatchMth
		)
		Select @jcco, @mckPO, null, @batchid, @batchmth

End

GO


Grant EXECUTE ON dbo.MCKspPOInsertLoad TO [MCKINSTRY\Viewpoint Users]