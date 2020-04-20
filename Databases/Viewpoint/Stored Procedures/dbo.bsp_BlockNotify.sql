SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       PROCEDURE [dbo].[bsp_BlockNotify]
     /********************************************
      * Created: GG 09/13/01
      * Modified: GG 05/30/03 - added hostnames to message
      * 		   GWC 10/05/2004 - Changed old style not equals to <>
      *
      * Usage:
      *	Alerts blocking processes which have existed for a specific # of minutes
      *
      ************************************************/
     	(@mailbox varchar(255) = null, @duration int = 2)
     as
     
     set nocount on
     
     declare @msg varchar(8000), @names varchar(8000)
     
     /*if (select datediff(mi,last_batch,getdate())
     	from master..sysprocesses
     	where blocked <> 0 )> @duration		-- duration in minutes*/
     
     set @names = ''
     select @names = @names + ', ' + rtrim(isnull(hostname,''))
     from master..sysprocesses
     where blocked <> 0  and datediff(mi,last_batch,getdate())> @duration		-- duration in minutes
     if @@rowcount > 0
     	begin
     	select @names = substring(@names,3,datalength(@names)+1)	-- strip leading comma and space
     
     	select @msg = 'The following host(s) have processes that have been blocked for at least ' + convert(varchar(3),@duration) + ' minutes:'	
     	select @msg = @msg + char(13) + @names
     	
     	if @mailbox is not null
     		exec master..xp_sendmail @recipients = @mailbox, @message = @msg, @subject = 'Blocked Processes'
     
     	raiserror (@msg, 16, 1) with log	-- record in current SQL Server log
     	end
     
     
     bspexit:
     	return

GO
GRANT EXECUTE ON  [dbo].[bsp_BlockNotify] TO [public]
GO
