SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUDCheckForOtherForms    Script Date: 8/28/99 9:32:34 AM ******/
     CREATE   proc [dbo].[vspHQUDGetRelatedFormTabs]
     /***********************************************************
      * CREATED BY	: JRK 07/18/07
      * MODIFIED BY	: 
      *
      * USED IN: frmVACustomFields
      *
      * USAGE: 
      * Get the tabs of related forms from DDFT.
      * INPUT PARAMETERS
      *  @form1 is required. (The first related form.)
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs
      * RETURN VALUE
      *   0         success
      *   1         Failure
      *****************************************************/
   
       (@form1 varchar(30) = null,
		@form2 varchar(30) = null,
		@form3 varchar(30) = null,
		@form4 varchar(30) = null,
		@form5 varchar(30) = null,
		@form6 varchar(30) = null,
		@form7 varchar(30) = null,
		@form8 varchar(30) = null,
		@msg varchar(30) output)
     as
	set nocount on
   
    declare @rcode int

    select @rcode = 0

	if @form1 = null
	begin
		select @rcode=1, @msg='No form specified!'
		goto bspexit
	end

	exec vspDDFTGet @form1

	if @form2 is not null
	begin
		exec vspDDFTGet @form2
	end
	if @form3 is not null
	begin
		exec vspDDFTGet @form3
	end
	if @form4 is not null
	begin
		exec vspDDFTGet @form4
	end
	if @form5 is not null
	begin
		exec vspDDFTGet @form5
	end
	if @form6 is not null
	begin
		exec vspDDFTGet @form6
	end
	if @form7 is not null
	begin
		exec vspDDFTGet @form7
	end
	if @form8 is not null
	begin
		exec vspDDFTGet @form8
	end

bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQUDGetRelatedFormTabs] TO [public]
GO
