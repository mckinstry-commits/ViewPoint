SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 07/03/2008
-- Description:	This is a validation procedure that will make sure the given DDFH Form
--				has a batch posting table.
-- =============================================
CREATE PROCEDURE dbo.vspDMBatchPostingTableValidation	
	@DDFHForm varchar(30), @returnMessage varchar(255)	output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @returnCode int
	SELECT @returnCode = 0	

    IF not exists (SELECT TOP 1 1 FROM DDFH WHERE Form = @DDFHForm and PostedTable is not null and AllowAttachments = 'Y')
    BEGIN
		SELECT @returnMessage = isnull(@DDFHForm, '[no form specified]') + ' does not have a batch posting table in DDFH.', @returnCode = 1
		GOTO vspExit
    END

vspExit:
	return @returnCode

END
GO
GRANT EXECUTE ON  [dbo].[vspDMBatchPostingTableValidation] TO [public]
GO
