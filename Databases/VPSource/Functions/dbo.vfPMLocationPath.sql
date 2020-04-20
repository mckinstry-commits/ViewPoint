SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE function [dbo].[vfPMLocationPath] 
(@location varchar(10) = null)
returns varchar(128)
as
begin
/***********************************************************
 * Created By:	GF 02/14/2007
 * Modified By:
 *
 *
 * USAGE:
 * Pass this function the HQWL location and it will return
 * a string with the location path.
 * 2 special conditions:
 * 'PMCustom'	Path:	'\Viewpoint Repository\Document Templates\Custom' - NOT USED
 * 'PMStandard'	Path:	'\Viewpoint Repository\Document Templates\Standard'
 *
 *
 *
 * INPUT PARAMETERS
 * location		HQWL location
 *
 * OUTPUT PARAMETERS
 * path			HQWL location path or viewpoint repository path
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure or nothing to format
 *****************************************************/
declare @path varchar(128)
  
if @location is null
	begin
	select @path = 'Missing Document Location!'
   	goto bspexit
   	end

----if @location = 'PMCustom'
----	begin
----	select @path = '\Viewpoint Repository\Document Templates\Custom'
----	goto bspexit
----	end

if @location = 'PMStandard'
	begin
	select @path = '\Viewpoint Repository\Document Templates\Standard'
	goto bspexit
	end

---- get location path
select @path=Path from HQWL where Location=@location
if @@rowcount = 0
	begin
	select @path='Location: ' + isnull(@location,'') + ' not on file!'
	end




bspexit:
	return(@path)
	end

GO
GRANT EXECUTE ON  [dbo].[vfPMLocationPath] TO [public]
GO
