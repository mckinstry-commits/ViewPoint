SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL vspDMAttachmentSearch
-- Create date: 1/21/2010
-- Description:	Executes the search passed in 
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentSearch] 
-- Add the parameters for the stored procedure here
	(@sql as varchar(8000))
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
				
	declare @rcode int
	select @rcode = 0

exec (@sql)

		
END

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentSearch] TO [public]
GO
