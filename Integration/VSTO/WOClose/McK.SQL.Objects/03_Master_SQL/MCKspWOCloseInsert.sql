USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspWOCloseInsert' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspWOCloseInsert'
	DROP PROCEDURE dbo.MCKspWOCloseInsert
End
GO

Print 'CREATE PROCEDURE dbo.MCKspWOCloseInsert'
GO


CREATE Procedure [dbo].MCKspWOCloseInsert
(
  @SMCo bCompany,
  @WO Varchar(255),
  @BatchMonth bMonth
)
AS
 /* 
	Purpose:	Close Work Orders		
	Created:	04/2018
	Author:		Leo Gurdian

	03.25.2019 LG - to align better error reporting in MCKspWOCloseProcess
	04/2018    LG - Initial
*/

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN

	DECLARE @errmsg VARCHAR(800) = ''

	BEGIN TRY

		INSERT INTO dbo.MCKWOCloseStage
		(	[Co],
			[WO],
			CloseStatus,
			BatchNum,
			BatchMth,
			ErrorMsg
		)
		SELECT 
		  @SMCo
		, @WO
		, 'Ready'
		, NULL
		, @BatchMonth
		, null

	END TRY

	BEGIN CATCH
		SET @errmsg =  ERROR_PROCEDURE() + ', ' + N'Line:' + CAST(ERROR_LINE() AS VARCHAR(MAX)) + ' | ' + ERROR_MESSAGE();
		GOTO i_exit
	END CATCH

i_exit:

	if (@errmsg <> '')
		BEGIN
		 RAISERROR(@errmsg, 11, -1);
		END

END


GO

Grant EXECUTE ON dbo.MCKspWOCloseInsert TO [MCKINSTRY\Viewpoint Users]

/* test 

 exec dbo.MCKspWOCloseInsert 1, '8007050', '2019-02-01' 

*/