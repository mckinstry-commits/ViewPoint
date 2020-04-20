SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspHQWDFileNameVal]
/***********************************************************
 * CREATED By:	GF 11/29/2001
 * MODIFIED By:	GF 10/30/2009 - issue #134090
 *
 *
 * USAGE:
 * validates HQ Document File Name to existing document templates
 *
 * PASS:
 * TemplateName, Location, FileName
 *
 * RETURNS:
 * TemplateType		Document Template Type
 * WordTable		Word Table Number if any
 * 
 * OUTPUT PARAMETERS
 * @msg     Error message if invalid, 
 * RETURN VALUE
 *   0 Success
 *   1 fail
 *****************************************************/ 
(@templatename bReportTitle, @location varchar(10), @filename varchar(60),
 @templatetype varchar(10) = null output, @wordtable tinyint = 0 output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- check if file name in use for location and get default information
select @templatetype=TemplateType, @wordtable=WordTable
from dbo.HQWD where FileName=@filename and TemplateName <> @templatename



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWDFileNameVal] TO [public]
GO
