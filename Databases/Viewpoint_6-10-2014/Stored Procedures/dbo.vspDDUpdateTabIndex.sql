SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspDDUpdateTabIndex]
/********************************
* Created: mj 6/9/04
* Modified:	GG 8/10/04
* 
* Called from the VPForm Class to update or remove overridden Tab Index values from Form Inputs
*
* Input:
*	@form		Form 
*	@seq		Form Input Sequence
*	@tabindex	Tab Index value - positive integer to override, null when removing override
*	
* Output:
*	@errmsg		error message
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @seq smallint = null, @tabindex varchar(20) = null, @errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0


if suser_sname()= 'viewpointcs' goto vspexit

if @form is null or @seq is null
	begin
	select @errmsg = 'Missing required input parameter(s): Form and/or Sequence #.', @rcode = 1
	goto vspexit
	end	

-- try to update existing custom input
if @tabindex is not null
	begin
	update vDDFIc
	set TabIndex = @tabindex
	where Form = @form and Seq = @seq
	if @@rowcount = 0
		begin
		-- add custom entry for Tab Index override
		insert vDDFIc (Form, Seq, TabIndex)
		values (@form, @seq, @tabindex)
		end
	end
else
	begin
	-- remove Tab Index override - remove custom Form Input if all values are null
	delete vDDFIc
	where Form = @form and Seq = @seq and ViewName is null and ColumnName is null
		and Description is null and Datatype is null and InputType is null and InputMask is null
		and InputLength is null and Prec is null and ActiveLookup is null
		and LookupParams is null and LookupLoadSeq is null and SetupForm is null
		and SetupParams is null and StatusText is null and Tab is null and Req is null	-- skip TabIndex
		and ValProc is null and ValParams is null and ValLevel is null and UpdateGroup is null
		and ControlType is null and ControlPosition is null and FieldType is null
		and DefaultType is null and DefaultValue is null and InputSkip is null and Label is null
		and ShowForm is null and ShowGrid is null and GridCol is null and AutoSeqType is null
	if @@rowcount = 0
		begin
		-- remove Tab Index override - entry has other custom values
		select * from vDDFIc
		where Form = @form and Seq = @seq
		If @@rowcount > 0 
			begin		
			update vDDFIc set TabIndex = null
			where Form = @form and Seq = @seq
			if @@rowcount = 0
				begin
				select @errmsg = 'Unable to remove Tab Index override.', @rcode = 1
				goto vspexit
				end
			end
		end	
	end

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDUpdateTabIndex]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUpdateTabIndex] TO [public]
GO
