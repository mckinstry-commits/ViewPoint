SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
















CREATE                PROCEDURE [dbo].[vspVPMenuGetColorSchemes]
/**************************************************
* Created:  MJ 9/22/05
*
* Used by the color picker form to retrieve color schemes.
*
* 
* Output
*	@errmsg
*
****************************************************/
as

declare @rcode int
select @rcode = 0	--not used at this point.


set nocount on 
	select *
	from DDCS
   
vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetColorSchemes] TO [public]
GO
