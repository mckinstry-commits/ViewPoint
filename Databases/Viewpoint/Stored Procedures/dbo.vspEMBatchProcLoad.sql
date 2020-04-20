SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMBatchProcLoad]
/***********************************
*
*	Created by: TV 02/09/06
*	Modified by:  TJL 07/24/07 - Add check for Menu Company (HQCo) in EM Module Company Master
*
*	Load proc for the batch 
* 	process form.
*
************************************/
(@EMCo bCompany, @AdjstGLLvl varchar(25) output, @UseGLLvl varchar(25) output,
 @MatlGLLvl varchar(25) output,@GLCo bCompany output, @attachbatchreports bYN output,
 @errmsg varchar(250) output)
as

set nocount on

declare @rcode int

select @rcode = 0

if @EMCo is null
	begin
  	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
else
	begin
	select top 1 1 
	from dbo.EMCO with (nolock)
	where EMCo = @EMCo
	if @@rowcount = 0
		begin
		select @errmsg = 'Company# ' + convert(varchar,@EMCo) + ' not setup in EM.', @rcode = 1
		goto vspexit
		end
	end

/* Get Interface Levels */
Select @GLCo=GLCo, @AdjstGLLvl = AdjstGLLvl, @UseGLLvl = UseGLLvl, 
@MatlGLLvl = MatlGLLvl,@attachbatchreports = IsNUll(AttachBatchReportsYN,'N')
from EMCO with(nolock)
where EMCo= @EMCo
if @@rowcount < 1 
	begin
	select @errmsg = 'Error getting EM Interface level information.', @rcode = 1
	goto vspexit
	end

vspexit:
if @rcode = 1 
	begin 
	select @errmsg = isnull(@errmsg,'')		--+ ' - vspEMBatchProcLoad'
	end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMBatchProcLoad] TO [public]
GO
