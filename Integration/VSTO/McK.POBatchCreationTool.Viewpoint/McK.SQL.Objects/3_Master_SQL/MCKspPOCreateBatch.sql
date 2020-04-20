USE [Viewpoint]
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspPOCreateBatch' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspPOCreateBatch'
	DROP PROCEDURE dbo.MCKspPOCreateBatch
End
GO

Print 'CREATE PROCEDURE dbo.MCKspPOCreateBatch'
GO

CREATE Procedure [dbo].[MCKspPOCreateBatch]
( @JCCo bCompany,
  @BatchMth bMonth,
  @Rbatchid bBatchID output  
)
AS
/*
	AUTHOR:	Leo Gurdian
	PURPOSE: Create Batch and return batch ID
	HISTORY:	
	-------	  -----------------------
	3.29.18	- Created
*/

SET NOCOUNT ON;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @source bSource = 'PO Entry'
	DECLARE @batchtable char(20) = 'POHB'
	DECLARE @restrict bYN = 'N'
	DECLARE @adjust bYN = 'N'
	DECLARE @prgroup bGroup = null 
	DECLARE @prenddate bDate = null
	DECLARE @Rerrmsg varchar(60) 

Begin
       exec @Rbatchid = bspHQBCInsert @JCCo,
				@BatchMth,
				@source,
				@batchtable,
				@restrict,
				@adjust,
				@prgroup,
				@prenddate,
				@errmsg= @Rerrmsg output
END

GO

Grant EXECUTE ON dbo.MCKspPOCreateBatch TO [MCKINSTRY\Viewpoint Users]