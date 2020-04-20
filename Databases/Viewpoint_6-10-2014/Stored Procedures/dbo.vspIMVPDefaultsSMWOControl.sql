SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspIMVPDefaultsSMWOControl]
/***********************************************************
* CREATED BY: JRE - 11/13/2012 TK14865 Create new Import for SM Work Orders
* MODIFIED BY: 		 
*
* Usage:
*	Used by Imports to create values for needed or missing
*      data based upon Viewpoint default rules. This will call 
*      corresponding bsp based on record type.
*
* Input params:
*	@ImportId	Import Identifier
*	@ImportTemplate	Import ImportTemplate
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
     
(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
     
as

set nocount on

declare @rcode int, @recode int, @desc varchar(120), @tablename varchar(10)

select @rcode = 0, @msg = ''

select @Form = Form from IMTR where RecordType = @rectype and ImportTemplate = @ImportTemplate
    
if @Form = 'SMWorkOrder'
	begin
	exec @rcode = dbo.vspIMVPDefaultsSMWorkOrder @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg output
	END
	
if @Form = 'SMWorkOrderScope'
	begin
	exec @rcode = dbo.vspIMVPDefaultsSMWOScope @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg OUTPUT
	end	

bspexit:
	select @msg = isnull(@desc,'SM Work Order') + char(13) + char(10) + '[vspIMVPDefaultsSMWOControl]'

	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspIMVPDefaultsSMWOControl] TO [public]
GO
