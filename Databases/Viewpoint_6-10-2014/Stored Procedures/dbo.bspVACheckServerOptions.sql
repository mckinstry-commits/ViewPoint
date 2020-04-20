SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspVACheckServerOptions]
 /***********************************************************
  * Created: GG 07/10/02 - #17803 check 'nested trigger' option
  * Modfied: danf 1/24/05 - issue #119669 (SQL 9.0 2005)
  *
  * Called from VPMenu to check required Server options
  * 
  * INPUT PARAMETERS
  *	none
  *
  * OUTPUT PARAMETERS
  *	@errmsg		    Message used for errors
  *
  * RETURN VALUE
  *	0 = success, 1 = fail
  *****************************************************/
 
 	(@errmsg varchar(1000) output)
 
 as
 
 declare @rcode int
 
 set nocount on
 
 select @rcode = 0


if (select CHARINDEX ( '- 8.' , left(@@version,charindex(char(10),@@version)-1) , 1 ))>0
	--if SQL 2000 use system table to check the setting on nested triggers.
    begin
	 -- check 'nested trigger' option - this code dependant on version of SQLServer - works for SQL2000
	 if (select u.value from master.dbo.spt_values v
	 	join master.dbo.syscurconfigs  u  on v.number = u.config
	 	where v.type = 'C  ' and v.name = 'nested triggers') <> 1
	 	begin
	 	select @errmsg = 'Server option for ''nested triggers'' is not set.  Viewpoint will not run properly.'
	 		+ char(13) + char(13) + 'Please contact your System Administrator and reconfigure this setting.', @rcode = 1
	 	goto bspexit
	 	end
 	end
 
if (select CHARINDEX ( '- 9.' , left(@@version,charindex(char(10),@@version)-1) , 1 ))>0
	begin
	--if SQL 2005 use system table to check the setting on nested triggers.
	 -- check 'nested trigger' option - this code dependant on version of SQLServer - works for SQL2005
	 if not exists(select top 1 1 from sys.configurations where name = 'nested triggers' and Value = 1) 
	 	begin
	 	select @errmsg = 'Server option for ''nested triggers'' is not set.  Viewpoint will not run properly.'
	 		+ char(13) + char(13) + 'Please contact your System Administrator and reconfigure this setting.', @rcode = 1
	 	goto bspexit
	 	end
 	end


 -- add'l checks made here
 
 
 bspexit:
     if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(13) + '[bspVACheckServerOptions]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVACheckServerOptions] TO [public]
GO
