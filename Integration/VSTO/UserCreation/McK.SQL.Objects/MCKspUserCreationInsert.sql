USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspUserCreationInsert' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspUserCreationInsert'
	DROP PROCEDURE dbo.MCKspUserCreationInsert
End
GO

Print 'CREATE PROCEDURE dbo.MCKspUserCreationInsert'
GO


CREATE Procedure [dbo].[MCKspUserCreationInsert]
( @co bCompany,
  @Role varchar(255),
  @UserName  varchar(255),
  @Name varchar(255),
  @Email varchar(255),
  @RequestedBy varchar(255),
  @Rbatchid bBatchID) as
  Begin
Insert into MCKVPUserCreation
([Co] ,
[Role],
	[UserName],
	[Name],
	[Email],
	[RequestedBy],
	[BatchNum] )
	select @co ,
  @Role ,
  @UserName ,
  @Name ,
  @Email,
  @RequestedBy ,
  @Rbatchid 
	end

GO


Grant EXECUTE ON dbo.MCKspUserCreationInsert TO [MCKINSTRY\Viewpoint Users]
