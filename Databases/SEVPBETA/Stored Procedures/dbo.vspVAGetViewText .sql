SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		jrk
-- Create date: 9/7/2007
-- Description:	Get a view's definition so we can examine the columns it uses.
-- =============================================
CREATE PROCEDURE dbo.[vspVAGetViewText ]
	-- Add the parameters for the stored procedure here
	@viewname varchar(30), @msg varchar(60) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @rcode int
	select @rcode=0
    -- Insert statements for procedure here
	select c.text ViewText from sys.syscomments c
	join sys.views v on c.id = v.object_id
	where v.name=@viewname

	if @@rowcount<>1
		select @rcode =1

	return @rcode
END



GO
GRANT EXECUTE ON  [dbo].[vspVAGetViewText ] TO [public]
GO
