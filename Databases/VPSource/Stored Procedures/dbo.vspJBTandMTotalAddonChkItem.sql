SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBTandMTotalAddonChkItem    Script Date:  ******/
CREATE proc [dbo].[vspJBTandMTotalAddonChkItem]
/******************************************************************************************************
* CREATED BY:  TJL 08/08/08 - Issue #128962, JB International Sales Tax.  Changes in JBID not updating JBIT correctly
* MODIFIED BY: 
*
*
* USED IN:
*	Used when a manual change occurs using the JB TM Bills Line Seq form
*
* USAGE:
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*
*
***********************************************************************************************************/
   
(@co bCompany,  @billmth bMonth, @billnum int, @template varchar(10), @itemempty bYN output, @msg varchar(275) output)
as

set nocount on

declare @rcode int
    
select @rcode = 0, @itemempty = 'Y'

if @billmth is null
	begin	
	select @msg = 'Missing Bill Month.', @rcode = 1
	goto vspexit
	end

if @billnum is null
	begin	
	select @msg = 'Missing Bill Number.', @rcode = 1
	goto vspexit
	end

if @template is null
	begin	
	select @msg = 'Missing Template.', @rcode = 1
	goto vspexit
	end

if exists(select top 1 1
	from bJBTS with (nolock)
	where JBCo = @co and Template = @template and ContractItem is not null)
	begin
	select @itemempty = 'N'
	end

vspexit:

if @rcode <> 0 
   	begin
   	select @msg = @msg
   	end
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTandMTotalAddonChkItem] TO [public]
GO
