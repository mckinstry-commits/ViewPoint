USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspVPUserCreationBatch' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspVPUserCreationBatch'
	DROP PROCEDURE dbo.MCKspVPUserCreationBatch
End
GO

Print 'CREATE PROCEDURE dbo.MCKspVPUserCreationBatch'
GO

CREATE Procedure [dbo].[MCKspVPUserCreationBatch]
( @co bCompany,
  @Rbatchid bBatchID output  
) 

AS

Begin

Select @Rbatchid =  isnull(max(isnull(CAST(BatchNum as INT),0)) + 1,1) from MCKVPUserCreation
    
END


Grant EXECUTE ON dbo.MCKspVPUserCreationBatch TO [MCKINSTRY\Viewpoint Users]
