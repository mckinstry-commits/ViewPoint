SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL 
-- Create date: 10/26/07
-- Description:	closes all connections and kills remote helper
-- =============================================
CREATE PROCEDURE [dbo].[vspVACloseConnections] WITH EXECUTE AS 'viewpointcs'
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
declare @name as nvarchar(128) ,@sqlcmd as varchar(250)

SELECT @name = DB_NAME()

SELECT @sqlcmd = 'ALTER DATABASE '+@name+ ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE'

Execute (@sqlcmd)

select @sqlcmd = 'ALTER DATABASE '+ @name+' SET MULTI_USER'

Exec (@sqlcmd)



--declare bcKill cursor for 
--select 'kill '+cast(Session_id as Varchar(4)) from sys.dm_exec_sessions
--where is_user_process = 1 --and login_name  ='vcspublic'
-- 
--open bcKill
--Fetch next from bcKill into @name
--while @@fetch_status = 0
--begin
--print @name
--set @sqlcmd =''
--set @sqlcmd =  @name 
--exec(@sqlcmd)
-- 
--Fetch next from bcKill into @name 
--End
--Close bcKill
--Deallocate bcKill
END


GO
GRANT EXECUTE ON  [dbo].[vspVACloseConnections] TO [public]
GO
