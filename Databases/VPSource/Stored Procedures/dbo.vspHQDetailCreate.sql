SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/12/2012
-- Description:	Creates a generic detail record
-- =============================================
CREATE PROCEDURE [dbo].[vspHQDetailCreate]
(
	@Source bSource, @HQDetailID bigint = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	INSERT dbo.vHQDetail ([Source])
	VALUES (@Source)
	
	SET @HQDetailID = SCOPE_IDENTITY()

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspHQDetailCreate] TO [public]
GO
