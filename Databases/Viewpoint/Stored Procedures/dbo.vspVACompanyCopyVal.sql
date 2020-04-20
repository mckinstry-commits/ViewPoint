SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspVACompanyCopyVal]
  /***********************************************************
   * CREATED BY: MV 06/05/07
   * MODIFIED By : 
   *              
   *
   * USAGE:
   * called from frmVACompanyCopyforServer to validate HQCo is setup in source database.
   * 
   * INPUT PARAMETERS
   *   SourceServer   
   *   SourceDB  
   *   HQCo
   *
   * OUTPUT PARAMETERS
   *    @msg If Error, error message, otherwise name of Company
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
	(@servername nvarchar(128), @dbname nvarchar(55),@hqco int,@name varchar(50) output,
	 @msg varchar(250)=null output)
  as
  SET nocount on
 
  declare @rcode int,@updatestring nvarchar(200),@islinked int, @retval int,@errmsg varchar(500);

  select @rcode = 0
  	
 if @servername is null
  	begin
  	select @msg = 'Missing source server name.', @rcode = 1
  	goto vspexit
  	end

 if @dbname is null
  	begin
  	select @msg = 'Missing source database name.', @rcode = 1
  	goto vspexit
  	end
  
if @hqco is null
  	begin
  	select @msg = 'Missing company number.', @rcode = 1
  	goto vspexit
  	end

--validate the source server
begin try
	select @islinked = is_linked from sys.servers where name = @servername
	if @@rowcount = 0
	begin
	select @msg = 'Invalid source server name.',@rcode=1
	goto vspexit;
	end
end try
begin catch
	select @msg = ERROR_MESSAGE(),@rcode=1
	goto vspexit;
end catch;

--validate the database name for linked servers
if @islinked = 1
begin
	declare @table TABLE(CATALOG_NAME varchar(50),DESCRIPTION varchar(50))
	insert into @table exec sp_catalogs @servername
	if not exists(select top 1 1 from @table where CATALOG_NAME= @dbname)
	begin
		select @msg = 'Invalid source database name.',@rcode=1
		goto vspexit;
	end
end

--validate hqco number
select @updatestring = N'select Name from ['+ rtrim(@servername) + '].' + rtrim(@dbname) + '.dbo.HQCO where HQCo=' +  convert(varchar,@hqco)
declare @table2 TABLE(Name varchar(50))
begin try
insert into @table2 exec (@updatestring)
if @@rowcount = 0
	begin
		select @msg = 'Company does not exist in HQCO.',@rcode=1
		goto vspexit
	end
else
	begin
	select @name = Name from @table2
	end    
end try
begin catch
	select @msg = ERROR_MESSAGE(),@rcode=1
	goto vspexit;
end catch

  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyVal] TO [public]
GO
