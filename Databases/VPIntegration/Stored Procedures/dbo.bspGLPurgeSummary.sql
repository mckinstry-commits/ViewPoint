SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLPurgeSummary]
/********************************************************
* Created: ??
* Modified: MV 01/31/03 - #20246 dbl quote cleanup.
*			GG 10/17/08 - #130666 - spelling correction
*
* Used by GL Purge program to delete Account Summary and Reference info.
*
* Updates bGLAS purge flag to 'Y', so that Account Balances
* and Yearly Balances are not backed out when rows are deleted.
*
* Pass: GL Company #, Through Month
*
* Returns: 0 and message if successful, 1 and message if error
*********************************************************/

   	(@glco bCompany = null, @fyemo bMonth = null, @msg varchar(255) output)
   
as
set nocount on
declare @rcode int, @lastmthglclsd bMonth, @lastfyemo bMonth, @topurge int

select @rcode = 0

/* check for missing GL Company */
if @glco is null
	begin
	select @msg = 'Missing GL Company #!', @rcode = 1
	goto bspexit
	end
   
/* check for missing Fiscal Year ending month */
if @fyemo is null
	begin
	select @msg = 'Missing Fiscal Year ending month to purge through!', @rcode = 1
	goto bspexit
	end

select @lastmthglclsd = LastMthGLClsd from bGLCO where GLCo = @glco
if @@rowcount = 0 
	begin
	select @msg = 'Invalid GL Company #!', @rcode = 1
	goto bspexit
	end

if not exists(select * from bGLFY where GLCo = @glco and FYEMO = @fyemo)
	begin
	select @msg = 'Invalid Fiscal Year ending month!', @rcode = 1
	goto bspexit
	end
   
/* get last fully closed Fiscal Year */
select @lastfyemo = max(FYEMO) from bGLFY where GLCo = @glco
	and FYEMO <= @lastmthglclsd
if @lastfyemo is null 
	begin
	select @msg = 'No previous Fiscal Year has been fully closed!', @rcode = 1
	goto bspexit
	end

if @fyemo > @lastfyemo
	begin
	select @msg = 'Can only purge through the last closed Fiscal Year!', @rcode = 1
	goto bspexit
	end
   
begin transaction
	/* update Purge flag in bGLAS */
	update bGLAS set Purge = 'Y'
		where GLCo = @glco and Mth <= @fyemo
	
	select @topurge = @@rowcount
	
	/* delete rows to be purged */
	delete bGLAS where GLCo = @glco and Purge = 'Y'
	
	if @@rowcount <> @topurge
		begin
		select @msg = 'Problems with Account Summary purge.  Nothing will be deleted!', @rcode = 1
		rollback transaction
		goto bspexit
		end
	
	/* delete GL References */
	delete bGLRF where GLCo = @glco and Mth <= @fyemo

commit transaction

select @msg = 'Successfully deleted Account Summary and Reference entries.'

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLPurgeSummary] TO [public]
GO
