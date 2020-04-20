SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************
  *	 Created by MV 09/08/05 - #27737 6X
  *  Modified by: TRL 02/20/08 - Issue 21452
  *		This procedure gets the interface levels and ICRptYN flag from APCO for APBatchProcess LoadProc 
  *
  ***********************************************************************************************************/
  
  CREATE  proc [dbo].[vspAPBatchPostingLoadProc]
  
  (@apco bCompany, @jc tinyint output, @cm tinyint output, @em tinyint output,
   @in tinyint output, @glexp tinyint output, @glpay tinyint output,@icrptyn bYN output, 
   @attachbatchreports bYN output, @msg varchar(60) output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
 
  Select @jc=JCInterfaceLvl, @cm=CMInterfaceLvl, @em=EMInterfaceLvl, @in=INInterfaceLvl,
    @glexp=GLExpInterfaceLvl, @glpay=GLPayInterfaceLvl, @icrptyn=ICRptYN, 
	@attachbatchreports=IsNull(AttachBatchReportsYN,'N') 
  from APCO where APCo=@apco
	if @@rowcount = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@apco) + ' not setup in AP', @rcode = 1
	goto vspexit
	end
  
  vspexit:
  if @rcode<>0 select @msg=@msg 
  return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPBatchPostingLoadProc] TO [public]
GO
