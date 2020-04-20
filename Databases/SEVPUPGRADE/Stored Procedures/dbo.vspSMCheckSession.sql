SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Modified:    Eric V   - 08/21/11 Added @Prebilling output parameter.
-- Create date: 11/9/10
-- Description:	Returns whether a session is locked and if so who has it locked
-- =============================================
CREATE PROCEDURE [dbo].[vspSMCheckSession]
	@SMSessionID int, @IsLocked bit OUTPUT, @UserName varchar(128) OUTPUT, @Prebilling bit OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SET @IsLocked = 1

    BEGIN TRY
		--If we are able to read the session record using NOWAIT right away then IsLocked will be set to 0
		--otherwise an exception will be thrown and we will grab the user that has it locked
        SELECT @IsLocked = 0, @Prebilling = Prebilling
        FROM SMSession WITH (NOWAIT)
        WHERE SMSessionID = @SMSessionID
    END TRY
    BEGIN CATCH
		--The record is locked so we read the username using NOLOCK so that we aren't prevented by the lock from reading the record
        SELECT @UserName = UserName, @Prebilling = Prebilling
        FROM SMSession WITH (NOLOCK)
        WHERE SMSessionID = @SMSessionID
    END CATCH
END

GO
GRANT EXECUTE ON  [dbo].[vspSMCheckSession] TO [public]
GO
