SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspVACompanyCopyHQCoVal]
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
   *    @msg If Error, error message, otherwise description of Company
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@servername varchar(55), @dbname varchar(55),@hqco int, @msg varchar(60)=null output)
  as
  
  set nocount on
    
  declare @rcode int,@updatestring varchar(200)

  select @rcode = 0
  	
 if @servername is null
  	begin
  	select @msg = 'Missing source server name.', @rcode = 1
  	goto bspexit
  	end

 if @dbname is null
  	begin
  	select @msg = 'Missing source database name.', @rcode = 1
  	goto bspexit
  	end
  
if @hqco is null
  	begin
  	select @msg = 'Missing company number.', @rcode = 1
  	goto bspexit
  	end

select @updatestring = null
select @updatestring = 'select Name from ['+ rtrim(@servername) + '].' + rtrim(@dbname) + '.dbo.HQCO where HQCo=' +  @hqco 
EXEC (@updatestring)
if @@rowcount = 0
  	begin
  	select @msg = 'company does not exist in HQCO.'
  	goto bspexit
  	end
    
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyHQCoVal] TO [public]
GO
