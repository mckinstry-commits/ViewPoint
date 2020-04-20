SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vspVATableLookup
-- =============================================
-- Author:		AL
-- Create date: 2/22/07
-- Description: Returns a dataset that contains all the table names
--				in ascending order.
-- =============================================
 
	(@msg varchar(255) output) 


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select TABLE_NAME from INFORMATION_SCHEMA.TABLES order by TABLE_NAME


END

GO
GRANT EXECUTE ON  [dbo].[vspVATableLookup] TO [public]
GO
