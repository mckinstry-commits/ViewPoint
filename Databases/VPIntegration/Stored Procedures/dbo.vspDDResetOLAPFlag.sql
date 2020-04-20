SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL vspDDResetOLAPFlag
-- Create date: 6/13/2008
-- Description:	Resets the OLAP processed flag in DDVS to false
-- =============================================
CREATE PROCEDURE [dbo].[vspDDResetOLAPFlag]
	
AS	    
BEGIN

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Update DDVS Set CubesProcessed = 'N'

	
END

GO
GRANT EXECUTE ON  [dbo].[vspDDResetOLAPFlag] TO [public]
GO
