SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspDDDocTypeVal]
/***********************************************************
* CREATED BY: Chris Gall 6/24/13
*			
* Val proc for DD Doc Type Registration to validate that
* a doc type is unigue to each record.
* 
*****************************************************/
(@Form varchar(30), @DocumentTypeName varchar(30),
 @msg varchar(60) = null output)
     
as
set nocount on

declare @rcode int
set @rcode = 0 

if @Form is null
	begin
	select @msg = 'Missing Form', @rcode = 1
	goto bspexit
	end

if @DocumentTypeName is null
	begin
	select @msg = 'Missing Document Type Name', @rcode = 1
	goto bspexit
	end

declare @existingForm varchar(30)
select @existingForm = Form from Document.DocumentType
where DocumentTypeName = @DocumentTypeName and Form <> @Form

if @existingForm is not null
	begin
	select @msg = 'Document Type already assigned to ' + @existingForm , @rcode = 1
	goto bspexit
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDocTypeVal] TO [public]
GO
