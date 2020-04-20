SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		AL vspVAUpdateAnalysisServerName
-- Create date: 6/25/2008
-- Modifications: AL #134907 7/22/2009 Modified to update Database name and job name 
-- Description:	Updates the Analysis Server Name
-- =============================================
CREATE PROCEDURE [dbo].[vspVAUpdateAnalysisServerName]
	-- Add the parameters for the stored procedure here
	 (@rcode integer = 0, @servername varchar(30), @databasename varchar(30), @jobname varchar(30), @msg varchar(60) output) as
   
BEGIN

	SET NOCOUNT ON;
	
	if @servername is null or @servername = ''
	begin
	select @msg = 'Server name cannot be blank', @rcode = 1
	goto vspexit
	end
	
		if @databasename is null or @databasename = ''
	begin
	select @msg = 'Database name cannot be blank', @rcode = 1
	goto vspexit
	end
	
			if @jobname is null or @jobname = ''
	begin
	select @msg = 'Job name cannot be blank', @rcode = 1
	goto vspexit
	end

    -- Insert statements for procedure here
	Update DDVS set AnalysisServer = @servername, OLAPJobName = @jobname, OLAPDatabaseName = @databasename
	

	
vspexit:

return @rcode
	
END


GO
GRANT EXECUTE ON  [dbo].[vspVAUpdateAnalysisServerName] TO [public]
GO
