SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMVGVal    Script Date:  ******/
CREATE  proc [dbo].[bspPMVGVal]
/*************************************
 * Created By:	GF 03/31/2004
 * Modified By: GF 03/21/2007 - 6.x #28097 re-code
 *
 *
 *
 * validates PM Document Tracking View
 *
 * Pass:
 * PM View Name
 *
 *
 * Success returns:
 *	0 and View Description
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@viewname varchar(10), @form varchar(30), @msg varchar(255) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

---- validate ViewName
if not exists(select ViewName from PMVM with (nolock) where ViewName=@viewname)
   	begin
   	select @msg = 'Invalid Document Tracking View: ' + isnull(@viewname,'') + ' !', @rcode = 1
   	goto bspexit
   	end


---- validate Grid Form
select @msg=GridTitle from PMVG with (nolock) where ViewName=@viewname and Form=@form
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Document Tracking Grid View: ' + isnull(@form,'') + '!', @rcode = 1
   	goto bspexit
   	end


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMVGVal] TO [public]
GO
