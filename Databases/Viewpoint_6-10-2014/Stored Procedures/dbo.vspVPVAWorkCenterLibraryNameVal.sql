SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspVPVAWorkCenterLibraryNameVal]
   /*************************************
   *Created by HH 03/28/13
   *Modified by 
   *			
   *
   * Usage:
   *	validates LibraryName
   *
   * Input params:
   *	@RefreshInterval	LibraryName to be validated
   *
   *Output params:
   *	@msg		error text
   *
   * Return code:
   *	0 = success, 1= failure
   *
   **************************************/
   	(@LibraryName varchar(50) = null, @Owner bVPUserName = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @Owner is null OR LTRIM(RTRIM(@Owner)) = ''
   	begin
   	select @msg = 'Missing Owner.', @rcode = 1
   	goto bspexit
   	end

   if not exists(SELECT 1 FROM DDUPExtended WHERE VPUserName = @Owner)
   begin
   	select @msg = '"' + @Owner + '" not a valid value.', @rcode = 1
   end

   if @LibraryName is null OR LTRIM(RTRIM(@LibraryName)) = ''
   	begin
   	select @msg = 'Missing Work Center Name.', @rcode = 1
   	goto bspexit
   	end
   
   if exists (SELECT 1 FROM vVPWorkCenterUserLibrary WHERE LibraryName = @LibraryName AND [Owner] = @Owner)
   begin
   	select @msg = '"' + @LibraryName + '" already exists for Owner "' + @Owner + '".', @rcode = 1
   end

   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVPVAWorkCenterLibraryNameVal] TO [public]
GO
